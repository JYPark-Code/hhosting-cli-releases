# 하나로호스팅 CLI(hh) 설치 — Windows (2026-09-28, 2026-09-29 GitHub Releases 로 이전)
#
#   irm https://raw.githubusercontent.com/JYPark-Code/hhosting-cli-releases/main/install.ps1 | iex
#
# 하는 일: GitHub Releases 에서 hh-windows-x64.exe 와 SHA256SUMS 를 받는다 → 체크섬 대조 →
# %LOCALAPPDATA%\hhosting\bin\hh.exe 에 설치 → 사용자 PATH 에 추가. 관리자 권한을 쓰지 않는다.
#
# 환경변수: HHOSTING_CLI_BASE(릴리스 주소, 기본 https://github.com/JYPark-Code/hhosting-cli-releases/releases)
#           HHOSTING_CLI_VERSION(예: 0.1.0 — 없으면 최신) · HHOSTING_INSTALL_DIR · HHOSTING_INSECURE_TEST=1 (install.sh 와 같다)
#           HHOSTING_NO_MODIFY_PATH=1 — 사용자 PATH 를 건드리지 않는다(시험·관리형 PC)

$ErrorActionPreference = 'Stop'

function Fail([string]$msg) { Write-Host "설치 실패: $msg" -ForegroundColor Red; throw $msg }

$base = if ($env:HHOSTING_CLI_BASE) { $env:HHOSTING_CLI_BASE.TrimEnd('/') } else { 'https://github.com/JYPark-Code/hhosting-cli-releases/releases' }
$dir = if ($env:HHOSTING_INSTALL_DIR) { $env:HHOSTING_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'hhosting\bin' }

if ($base -like 'http://*') {
  if ($env:HHOSTING_INSECURE_TEST -ne '1') { Fail "배포 주소가 https 가 아닙니다: $base (시험이면 HHOSTING_INSECURE_TEST=1)" }
  Write-Host '경고: 평문 HTTP 로 설치합니다(시험 전용).' -ForegroundColor Yellow
} elseif ($base -notlike 'https://*') {
  Fail "배포 주소 형식이 올바르지 않습니다: $base"
}

$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -ne 'AMD64') { Fail "지원하지 않는 CPU 입니다: $arch (현재 x64 만 배포)" }
$name = 'hh-windows-x64.exe'

# PowerShell 5.1 기본값이 TLS 1.0 인 환경이 있다.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("hh-install-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  # GitHub Releases 주소 규칙: 최신 = <BASE>/latest/download/<파일> · 고정 = <BASE>/download/v<버전>/<파일>
  if ($env:HHOSTING_CLI_VERSION) {
    $version = $env:HHOSTING_CLI_VERSION
    if ($version -notmatch '^[0-9A-Za-z.-]+$') { Fail "버전 문자열이 올바르지 않습니다: $version" }
    $from = "$base/download/v$version"
    Write-Host "hh $version ($name) 를 받는 중…"
  } else {
    $from = "$base/latest/download"
    Write-Host "hh 최신 버전 ($name) 를 받는 중…"
  }

  $exe = Join-Path $tmp $name
  $sums = Join-Path $tmp 'SHA256SUMS'
  Invoke-WebRequest -UseBasicParsing "$from/$name" -OutFile $exe
  Invoke-WebRequest -UseBasicParsing "$from/SHA256SUMS" -OutFile $sums

  $line = Get-Content $sums | Where-Object { ($_ -split '\s+')[1] -eq $name } | Select-Object -First 1
  if (-not $line) { Fail "체크섬 목록에 $name 이 없습니다." }
  $expected = ($line -split '\s+')[0].ToLower()
  $actual = (Get-FileHash -Algorithm SHA256 $exe).Hash.ToLower()
  if ($expected -ne $actual) { Fail "체크섬이 다릅니다 — 받은 파일을 설치하지 않았습니다. (기대 $expected · 실제 $actual)" }

  # 서명돼 있으면 확인한다. 아직 서명 전 배포라면 NotSigned 로 지나간다(docs/배포_네이티브설치.md §서명).
  $sig = Get-AuthenticodeSignature $exe
  if ($sig.Status -ne 'Valid' -and $sig.Status -ne 'NotSigned') { Fail "코드 서명이 올바르지 않습니다: $($sig.Status)" }

  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Move-Item -Force $exe (Join-Path $dir 'hh.exe')
  Write-Host "설치했습니다: $(Join-Path $dir 'hh.exe') ($(& (Join-Path $dir 'hh.exe') version))"

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($env:HHOSTING_NO_MODIFY_PATH -eq '1') {
    Write-Host "PATH 는 바꾸지 않았습니다(HHOSTING_NO_MODIFY_PATH=1)."
  } elseif (-not (($userPath -split ';') -contains $dir)) {
    [Environment]::SetEnvironmentVariable('Path', ($(if ($userPath) { "$userPath;$dir" } else { $dir })), 'User')
    $env:Path = "$env:Path;$dir"
    Write-Host "사용자 PATH 에 $dir 를 추가했습니다. 새 터미널부터 적용됩니다."
  }
  Write-Host ''
  Write-Host '다음: hh login'
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
