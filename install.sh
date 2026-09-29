#!/bin/sh
# 하나로호스팅 CLI(hh) 설치 — Linux (2026-09-28, 2026-09-29 GitHub Releases 로 이전)
#
#   curl -fsSL https://raw.githubusercontent.com/JYPark-Code/hhosting-cli-releases/main/install.sh | sh
#
# 하는 일: OS·CPU 판별 → GitHub Releases 에서 hh-<플랫폼> 과 SHA256SUMS 를 받는다 → 체크섬 대조 → ~/.local/bin/hh 에 설치.
# 체크섬이 다르면 설치하지 않는다. 관리자 권한(sudo)을 쓰지 않는다.
# macOS 는 아직 배포하지 않는다(운영자 결정 2026-09-29 — Apple 서명·공증은 당분간 검토하지 않음).
#
# 환경변수:
#   HHOSTING_CLI_BASE     릴리스 주소(기본 https://github.com/JYPark-Code/hhosting-cli-releases/releases)
#   HHOSTING_CLI_VERSION  설치할 버전(예: 0.1.0 — 없으면 최신)
#   HHOSTING_INSTALL_DIR  설치 위치(기본 ~/.local/bin)
#   HHOSTING_INSECURE_TEST=1  http:// 배포 주소 허용(시험 전용 — 실행 파일 바꿔치기를 막지 못한다)
set -eu

BASE="${HHOSTING_CLI_BASE:-https://github.com/JYPark-Code/hhosting-cli-releases/releases}"
BASE="${BASE%/}"
DIR="${HHOSTING_INSTALL_DIR:-$HOME/.local/bin}"

fail() { printf '설치 실패: %s\n' "$1" >&2; exit 1; }

case "$BASE" in
  https://*) ;;
  http://*)
    [ "${HHOSTING_INSECURE_TEST:-}" = "1" ] || fail "배포 주소가 https 가 아닙니다: $BASE (시험이면 HHOSTING_INSECURE_TEST=1)"
    printf '경고: 평문 HTTP 로 설치합니다(시험 전용).\n' >&2 ;;
  *) fail "배포 주소 형식이 올바르지 않습니다: $BASE" ;;
esac

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) fail "macOS 용 hh 는 아직 배포하지 않습니다." ;;
  *) fail "지원하지 않는 OS 입니다: $(uname -s) (Windows 는 install.ps1 을 쓰세요)" ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=x64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) fail "지원하지 않는 CPU 입니다: $(uname -m)" ;;
esac
name="hh-$os-$arch"

if command -v curl >/dev/null 2>&1; then
  get() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  get() { wget -qO "$2" "$1"; }
else
  fail "curl 또는 wget 이 필요합니다."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# GitHub Releases 주소 규칙: 최신 = <BASE>/latest/download/<파일> · 고정 = <BASE>/download/v<버전>/<파일>
if [ -n "${HHOSTING_CLI_VERSION:-}" ]; then
  version="$HHOSTING_CLI_VERSION"
  case "$version" in
    *[!0-9A-Za-z.-]*) fail "버전 문자열이 올바르지 않습니다: $version" ;;
  esac
  from="$BASE/download/v$version"
  printf 'hh %s (%s) 를 받는 중…\n' "$version" "$name"
else
  from="$BASE/latest/download"
  printf 'hh 최신 버전 (%s) 를 받는 중…\n' "$name"
fi

get "$from/$name" "$tmp/$name" || fail "실행 파일을 받지 못했습니다: $from/$name"
get "$from/SHA256SUMS" "$tmp/SHA256SUMS" || fail "체크섬 목록을 받지 못했습니다."

expected="$(awk -v n="$name" '$2 == n { print $1 }' "$tmp/SHA256SUMS")"
[ -n "$expected" ] || fail "체크섬 목록에 $name 이 없습니다."
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$tmp/$name" | awk '{print $1}')"
else
  actual="$(shasum -a 256 "$tmp/$name" | awk '{print $1}')"
fi
[ "$expected" = "$actual" ] || fail "체크섬이 다릅니다 — 받은 파일을 설치하지 않았습니다. (기대 $expected · 실제 $actual)"

mkdir -p "$DIR"
chmod 755 "$tmp/$name"
mv "$tmp/$name" "$DIR/hh"
printf '설치했습니다: %s (%s)\n' "$DIR/hh" "$("$DIR/hh" version 2>/dev/null || echo '?')"

case ":$PATH:" in
  *":$DIR:"*) ;;
  *) printf '\n%s 가 PATH 에 없습니다. 셸 설정(~/.bashrc · ~/.zshrc)에 다음 줄을 추가하세요:\n  export PATH="%s:$PATH"\n' "$DIR" "$DIR" ;;
esac
printf '\n다음: hh login\n'
