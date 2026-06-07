# 진행 로그 (claude-progress.md)

> 작업 단위로 추가. 최신 항목이 위. "완료"는 검증 명령 통과를 확인한 경우만.

## 2026-06-07

### 문서·CI 동기화 (인프라 전환 stale 정리)
- **인프라 전환 반영:** 자체 db·Caddy 제거 → 공유 sprout-infra 사용(외부 네트워크 sprout-shared). 이 repo는 backend-blue/green만 유지.
- AGENTS.md: 저장소 구조 설명(`docker-compose.yml ← backend-blue/green만`), DoD 백엔드 기동 명령(`backend-blue`, sprout-infra 사전 기동 명시), 백엔드 E2E MariaDB 사전 조건 갱신.
- HLD.md §3.1: MariaDB synchronize 조건부(`NODE_ENV!==production`) 반영. §3 AUTH→OPENAI 화살표 오류 수정(google-auth-library로 정정). §7 배포 다이어그램을 blue/green+sprout-infra 공유 구조로 교체.
- LLD.md §1·§2: synchronize 조건부 설명 갱신.
- CI ci.yml: backend-smoke 잡을 compose 실행 불가(sprout-shared external 네트워크, 호스트 포트 미노출) 이유 주석과 함께 `docker build` 이미지 빌드 검증으로 교체.
- docs/deploy/mac-mini-cloudflare-tunnel.md: 백업·DB 포트 섹션을 sprout-infra 소관으로 정정, DB_ROOT_PASSWORD 기입 안내 제거, 운영 점검 체크리스트 분리(sprout-infra/pretty-four).
- feature_list.json: audio-privacy 검증 명령 `backend` → `backend-blue`, updated 날짜 갱신.
- clean-state-checklist.md: 백엔드 기동 명령 `backend` → `backend-blue` + sprout-infra 사전 기동 명시.
- session-handoff.md: 최종 갱신일·현황 갱신.

## 2026-05-31

### 하네스 개선 5종 (Linear DJS-5~9, A등급 목표)
- **DJS-7 WIP=1 규율:** AGENTS.md §6에 단일 활성 작업 규칙, feature_list `active` 마커 + "wip≤1" 불변식, clean-state 체크 추가. 검증: `jq` 불변식 true.
- **DJS-8 아키텍처 가드:** `scripts/arch-guard.sh`(보호 라우트 `@UseGuards(JwtAuthGuard)` + 엔티티/DTO camelCase 검사, 위반 시 what/why/how-to-fix). CI `arch-guard` job. 검증: 정상 exit 0, 의도적 위반 exit 1.
- **DJS-5 백엔드 테스트:** Jest 단위(auth/children/sessions, mocked repo) 11개 + supertest E2E(auth 201/200/401/409/400, children 401/201 camelCase/200) 8개. `npm run test`/`test:e2e` 스크립트. AGENTS.md §4 DoD·feature_list 갱신. 검증: 단위 11 pass, E2E 8 pass, `npm run check` exit 0.
- **DJS-9 구조적 로깅:** CorrelationIdMiddleware + LoggingInterceptor(APP_INTERCEPTOR) → 요청 JSON 로그(correlationId/method/path/status/latencyMs). analysis 파이프라인 단계 로그. PII·본문·오디오 경로 미기록. 검증: 기동 후 `grep correlationId` 확인.
- **DJS-6 CI 3단계:** ci.yml에 backend(정적+단위)·backend-e2e(MariaDB 서비스)·backend-smoke(docker 기동 스모크) 분리. AI 파이프라인 수동검증 문서 `docs/manual-ai-pipeline-check.md`. AGENTS.md §4에 3단계 종결 검증 구조.

## 2026-05-30

### 하네스 정비 (A등급 목표)
- 진입 문서 `AGENTS.md`, `README.md`, `init.sh`, `.nvmrc`, `feature_list.json`, 상태 아티팩트 추가.
- 백엔드 `npm run typecheck`/`check` 스크립트 + `engines.node` 추가.
- **검증 격차 수정:** `analysis_result_test.dart`가 camelCase 마이그레이션 후 깨져 있던 것 발견 → 키 정정 → `flutter test` 13/13 통과.
- 검증: `flutter analyze`(clean), `flutter test`(13 pass), `npm run check`(exit 0).

### 디자인 적용
- 소프트 파스텔(민트&블루) 디자인 시스템(`core/theme.dart`, `widgets/app_widgets.dart`) + 7개 화면 리디자인.
- 앱 이름 "이쁜네살" 적용. UI 시안: `docs/design/preview.html`.
- "저장된 음성으로 분석" → `file_picker`로 기기 음성 파일 선택. 업로드 시 실제 확장자 보존(백엔드 포함).

### 백엔드 전환 (Supabase → NestJS)
- Supabase 제거, NestJS 10 + TypeORM + MariaDB(Docker) 백엔드 구축.
- 인증(이메일/구글/카카오 JWT), 아이 프로필, 세션, AI 분석 모듈.
- Flutter를 dio + JWT(secure storage) API 클라이언트로 전환. 모델 키 camelCase 정합.
- `esModuleInterop`로 form-data import 런타임 오류 수정.
- 설계 문서 `docs/HLD.md`, `docs/LLD.md` 추가, 기존 스펙 갱신.

## 다음 할 일
- [ ] 소셜 로그인 실기기 E2E 검증 (GOOGLE_CLIENT_ID/카카오 앱키 설정).
- [ ] 백엔드 단위/통합 테스트 추가(현재 typecheck+build만).
- [ ] CI 파이프라인(.github/workflows) 추가 — DoD 명령 자동 실행.
- [ ] 폴링 타임아웃, 업로드 중단 복구 등 견고성 개선(LLD 비고 참조).
