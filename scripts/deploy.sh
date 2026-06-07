#!/bin/bash
# 무중단 배포: 새 이미지 빌드 → blue 재생성 (green이 트래픽) → green 재생성 (blue가 트래픽)
# 두 인스턴스가 항상 살아있고 sprout-infra 엣지 Caddy가 헬스 기반으로 라우팅하므로 사용자 다운타임 0.
# (엣지 라우팅: ../sprout-infra/caddy/sites/pretty-four.caddy)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

wait_healthy() {
	local svc="$1"
	local timeout=60
	local elapsed=0
	echo "  → $svc 헬스 대기 중..."
	while [ $elapsed -lt $timeout ]; do
		local status
		status=$(docker inspect --format='{{.State.Health.Status}}' "pretty-four-${svc}-1" 2>/dev/null || echo "missing")
		if [ "$status" = "healthy" ]; then
			echo "  ✓ $svc healthy ($elapsed s)"
			return 0
		fi
		sleep 2
		elapsed=$((elapsed + 2))
	done
	echo "  ✗ $svc 타임아웃 ($timeout s) — 배포 중단"
	return 1
}

echo "==> 1) 새 이미지 빌드"
docker compose build backend-blue

echo ""
echo "==> 2) backend-blue 재생성"
docker compose up -d --no-deps --force-recreate backend-blue
wait_healthy backend-blue

echo ""
echo "==> 3) backend-green 재생성"
docker compose up -d --no-deps --force-recreate backend-green
wait_healthy backend-green

echo ""
echo "==> 배포 완료"
docker compose ps
