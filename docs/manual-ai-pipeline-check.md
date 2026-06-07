# AI 파이프라인 수동 검증 체크리스트

> Whisper(STT) + Claude(코칭 분석) 파이프라인은 **외부 API 키와 실제 음성**이 필요해 CI에서 자동화하지 않는다.
> 분석 로직(`analysis.service`)을 변경했을 때 아래 절차로 **수동 검증**하고, 통과 시에만 `feature_list.json`의
> `ai-pipeline` 항목을 `pass`로 유지한다. (3단계 종결 검증의 E2E 단계 — AGENTS.md §4 참조)

## 전제
- [ ] `backend/.env`에 유효한 `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 설정
- [ ] `./init.sh`로 백엔드+DB 기동 (`docker compose up -d --build`)
- [ ] 테스트용 음성 파일 준비 (예: `pretty_four/assets/sample.m4a`, 부모-아이 대화 ~25초)

## 절차
1. [ ] 앱에서 로그인 → 아이 프로필 생성(연령 입력)
2. [ ] 녹음 또는 "저장된 음성으로 분석"으로 음성 업로드 → `/processing` 진입
3. [ ] 폴링이 끝나고 결과 화면 진입까지 대기

## 기대 결과 (모두 충족해야 pass)
- [ ] 세션 상태가 `completed`로 전환 (`GET /sessions/:id` → `status: "completed"`)
- [ ] 결과 화면에 **요약 카드**(tone/patterns/improvements) 표시
- [ ] **타임스탬프 피드백**이 1건 이상, 각 항목에 `timestamp_sec`/`original`/`suggestion`/`reason` 포함
- [ ] 코칭 내용이 **입력한 연령대**에 맞게 반영됨 (예: 만 2~3세면 짧은 문장·감정 이름 붙이기 권장)
- [ ] **오디오 즉시 삭제 확인**: `docker compose exec backend-blue ls /app/uploads` → 비어 있음 (audio-privacy)

## 관측성 (DJS-9 로깅으로 추적)
- [ ] 분석 중 백엔드 로그에 단계별 JSON이 동일 `correlationId`로 남는다:
      `docker compose logs backend-blue | grep '"stage"'`
      → `analysis.start` → `transcribe.start/done` → `analyze.start/done` → `analysis.completed` → `audio.deleted`
- [ ] 실패 시 `analysis.failed`(error/message 포함) 로그로 원인 추적 가능

## 실패 시
- 세션이 `failed`로 끝나면 `correlationId`로 로그를 추적해 전사/분석 중 어느 단계인지 확인한다.
- 키 누락/과금 한도/네트워크 오류가 흔한 원인 (Whisper 분당 $0.006, Claude 토큰 과금).
