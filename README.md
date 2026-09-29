# 하나로호스팅 CLI (hh) — 배포

하나로호스팅 VPS 를 명령줄·AI 에이전트에서 다루는 `hh` 의 설치 파일을 배포하는 곳입니다.
소스 코드는 이 레포에 없습니다. 이 레포에는 설치 스크립트와 [Releases](../../releases) 의 실행 파일만 있습니다.

## 설치

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/JYPark-Code/hhosting-cli-releases/main/install.ps1 | iex
```

Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/JYPark-Code/hhosting-cli-releases/main/install.sh | sh
```

설치 스크립트는 최신 릴리스의 실행 파일과 `SHA256SUMS` 를 받아 **체크섬이 맞을 때만** 설치합니다.
관리자 권한을 쓰지 않습니다(Windows `%LOCALAPPDATA%\hhosting\bin`, Linux `~/.local/bin`).
특정 버전은 `HHOSTING_CLI_VERSION=0.1.0` 으로 고정할 수 있습니다.

macOS 용은 아직 배포하지 않습니다.

## 설치 후

```sh
hh login     # 브라우저에서 승인하면 API 키가 이 PC 에 저장됩니다
hh help
```

서버 개통·해지·스냅샷 삭제/되돌리기는 CLI 가 요청만 하고, 계정 주인이 브라우저에서 승인해야 실행됩니다.
