#!/usr/bin/env bash
#
# arch-guard.sh — 실행 가능 아키텍처 가드
#
# AGENTS.md §5의 핵심 불변식을 "산문 규칙"이 아니라 "런타임 체크"로 강제한다.
# 위반 시 무엇/왜/해결(how-to-fix) 메시지를 출력하고 비0으로 종료한다(에이전트 자기수정 루프).
#
# 사용법:  bash scripts/arch-guard.sh
# 통과:    exit 0
# 위반:    exit 1 (+ 진단 메시지)
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/backend/src"
fail=0

# 공개(인증 불필요) 라우트로 허용된 컨트롤러. 이 목록에 없는 컨트롤러는 보호 대상으로 간주한다.
PUBLIC_CONTROLLERS="auth.controller.ts"

# --- ① 보호 라우트 가드 검사 -------------------------------------------------
# 보호 대상 컨트롤러는 클래스에 @UseGuards(JwtAuthGuard)가 있어야 한다.
while IFS= read -r ctrl; do
  base="$(basename "$ctrl")"
  case " $PUBLIC_CONTROLLERS " in *" $base "*) continue ;; esac
  if ! grep -q "@UseGuards(JwtAuthGuard)" "$ctrl"; then
    echo "✖ [가드 누락] ${ctrl#"$ROOT"/}"
    echo "   무엇: 보호 대상 컨트롤러에 @UseGuards(JwtAuthGuard)가 없습니다."
    echo "   왜:   AGENTS.md §5 — 보호 라우트는 JwtAuthGuard로 인증을 강제해야 합니다."
    echo "         누락 시 인증 없이 타인의 데이터에 접근할 수 있습니다."
    echo "   해결: 컨트롤러 클래스 위에 @UseGuards(JwtAuthGuard)를 추가하세요."
    echo "         공개가 의도라면 scripts/arch-guard.sh의 PUBLIC_CONTROLLERS에 '$base'를 등록하세요."
    fail=1
  fi
done < <(find "$SRC" -name '*.controller.ts')

# --- ② 모델 키 규칙(camelCase) 검사 ------------------------------------------
# 엔티티/DTO의 TS 프로퍼티는 camelCase여야 한다(TypeORM 기본 응답 키와 일치).
# snake_case 식별자(예: timestamp_sec:) 금지.
# 참고: Claude 생성 JSON(FeedbackItem.timestamp_sec 등)은 TS 프로퍼티가 아니라
#       저장 JSON 값이므로 이 검사 대상이 아니다(엔티티/DTO 파일에만 적용).
while IFS= read -r f; do
  hits="$(grep -nE '^[[:space:]]+[a-z][a-zA-Z0-9]*_[a-z0-9_]*[[:space:]]*[?:]' "$f" || true)"
  if [ -n "$hits" ]; then
    echo "✖ [모델 키 규칙 위반] ${f#"$ROOT"/}"
    echo "$hits" | sed 's/^/        /'
    echo "   무엇: 엔티티/DTO에 snake_case 프로퍼티가 있습니다."
    echo "   왜:   AGENTS.md §5 — 엔티티 응답은 camelCase. Flutter fromJson과 키가 어긋나면"
    echo "         'Null is not a subtype of String' 파싱 오류가 발생합니다."
    echo "   해결: 프로퍼티명을 camelCase로 바꾸세요 (예: timestamp_sec → timestampSec)."
    fail=1
  fi
done < <(find "$SRC" \( -path '*/entities/*.entity.ts' -o -path '*/dto/*.ts' \))

# --- 결과 -------------------------------------------------------------------
if [ "$fail" -eq 0 ]; then
  echo "✓ arch-guard: 모든 불변식 통과 (보호 라우트 가드 + 모델 키 camelCase)"
fi
exit "$fail"
