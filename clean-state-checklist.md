# 클린 스테이트 체크리스트 (clean-state-checklist.md)

> 커밋·PR·"완료" 주장 전에 반드시 통과. **주장하지 말고 실행해서 확인한다.**

## 검증 (모두 통과해야 함)
- [ ] `cd pretty_four && flutter analyze` → `No issues found!`
- [ ] `cd pretty_four && flutter test` → `All tests passed!` (현재 13개)
- [ ] `cd backend && npm run check` → exit 0 (typecheck + build)
- [ ] (분석 변경 시) `docker compose up -d --build backend` → `Server running on port 3000`

## 위생
- [ ] 비밀키 미커밋: `git diff --cached --name-only | grep -E '\.env$'` 결과 없음
- [ ] 빌드 산물/의존성 미커밋: `node_modules`, `dist`, `build/`, `.omc/` 없음
- [ ] 디버그 코드/임시 로그 제거 (필요한 `kDebugMode` 분기는 예외)

## git (중첩 저장소 주의)
- [ ] Flutter 변경은 `pretty_four/`에서 먼저 커밋
- [ ] 그 후 부모에서 `git add pretty_four`로 gitlink 갱신 커밋
- [ ] Conventional Commits 형식 (`feat`/`fix`/`docs`/`chore`/`refactor` + scope)

## 상태 문서 갱신
- [ ] `claude-progress.md`에 이번 작업 1줄 이상 기록
- [ ] 기능 상태 변동 시 `feature_list.json`의 `status`/`evidence` 갱신
- [ ] 세션 종료 시 `session-handoff.md` 갱신
- [ ] WIP=1 확인: `jq -e '[.features[] | select(.status=="wip")] | length <= 1' feature_list.json` → `true` (활성 작업 1개 이하)

## 완료 주장 규칙
- [ ] "통과/완료"는 위 명령을 **실제 실행한 출력**으로만 주장한다. 파일이 통과한다고 *말하는* 것은 증거가 아니다.
