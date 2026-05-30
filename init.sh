#!/usr/bin/env bash
#
# init.sh — 이쁜네살 재현 가능한 환경 설정
# 백엔드(Docker: NestJS + MariaDB) 기동 + Flutter 의존성 설치까지 한 번에.
#
# 사용법:  ./init.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31m✖ %s\033[0m\n' "$1"; exit 1; }

# --- 0. 사전 도구 확인 ----------------------------------------------------
say "사전 도구 확인"
command -v docker >/dev/null   || fail "Docker가 필요합니다: https://docs.docker.com/get-docker/"
command -v flutter >/dev/null  || fail "Flutter가 필요합니다: https://flutter.dev/setup"
docker info >/dev/null 2>&1     || fail "Docker 데몬이 실행 중이 아닙니다. Docker Desktop을 켜세요."
echo "✓ docker, flutter 확인"

# --- 1. 백엔드 환경변수 -----------------------------------------------------
say "백엔드 .env 확인"
if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
  echo "⚠ backend/.env 를 생성했습니다. OPENAI_API_KEY / ANTHROPIC_API_KEY 를 채운 뒤 다시 실행하세요."
  echo "  (로그인·프로필까지는 키 없이도 동작하지만, AI 분석에는 키가 필요합니다.)"
else
  echo "✓ backend/.env 존재"
fi

# --- 2. 백엔드 + DB 기동 (Docker) ------------------------------------------
say "백엔드 + MariaDB 기동 (docker compose)"
docker compose up -d --build
echo "✓ 컨테이너 기동 요청 완료"

# --- 3. 백엔드 헬스 대기 ----------------------------------------------------
say "백엔드 기동 대기 (http://localhost:3000)"
for i in $(seq 1 30); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:3000/auth/login \
            -H 'Content-Type: application/json' -d '{}' 2>/dev/null || true)"
  # 400(검증 실패) 또는 401 이면 서버가 살아있다는 뜻
  if [ "$code" = "400" ] || [ "$code" = "401" ]; then
    echo "✓ 백엔드 응답 정상 (HTTP $code)"; break
  fi
  [ "$i" = "30" ] && fail "백엔드가 시간 내 기동하지 않았습니다. 'docker compose logs backend' 확인."
  sleep 2
done

# --- 4. Flutter 의존성 ------------------------------------------------------
say "Flutter 의존성 설치 (flutter pub get)"
( cd pretty_four && flutter pub get )
echo "✓ Flutter 의존성 설치 완료"

# --- 5. 앱 .env 확인 --------------------------------------------------------
say "앱 .env 확인"
if [ ! -f pretty_four/.env ]; then
  printf 'API_BASE_URL=http://localhost:3000\nKAKAO_NATIVE_APP_KEY=YOUR_KAKAO_NATIVE_APP_KEY\nGOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID\n' > pretty_four/.env
  echo "✓ pretty_four/.env 생성 (기본값)"
else
  echo "✓ pretty_four/.env 존재"
fi

say "완료! 이제 앱을 실행하세요:  cd pretty_four && flutter run"
