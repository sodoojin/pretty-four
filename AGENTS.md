# AGENTS.md — 이쁜네살 (Pretty Four)

> AI 에이전트·개발자를 위한 **진입 문서**. 이 저장소에서 작업하기 전에 이 파일을 먼저 읽으세요.
> 상세 설계는 링크를 따라가세요(점진적 공개). 이 파일은 짧게 유지합니다.

## 1. 프로젝트 개요

부모가 아이와의 일상 대화를 녹음하면, AI가 분석해 **연령별 훈육 코칭**을 제공하는 모바일 앱.

- **흐름:** 녹음 → 업로드 → Whisper(STT) → Claude(코칭 분석) → 결과 조회. 분석 후 오디오는 즉시 삭제.
- **상태:** MVP. 단일 아이 프로필, 이메일/구글/카카오 로그인.

## 2. 저장소 구조 (모노레포 + 중첩 git)

```
pretty-four/                  ← 부모 git 저장소 (백엔드·문서·인프라)
├── AGENTS.md                 ← (이 파일) 진입 문서
├── README.md                 ← 빠른 시작
├── init.sh                   ← 재현 가능한 환경 설정 (한 번에 셋업)
├── feature_list.json         ← 기계가 읽는 기능 목록 + 검증 명령
├── docker-compose.yml        ← backend + MariaDB
├── backend/                  ← NestJS 10 + TypeORM + MariaDB
│   └── src/{auth,users,children,sessions,analysis}/
├── pretty_four/              ← Flutter 앱 (별도 중첩 git 저장소!)
│   ├── lib/{core,services,models,screens,widgets}/
│   └── test/
└── docs/
    ├── HLD.md                ← 고수준 설계(아키텍처·데이터흐름)
    ├── LLD.md                ← 상세 설계(API·스키마·화면)
    ├── design/preview.html   ← UI 디자인 시안
    └── superpowers/{specs,plans}/
```

> ⚠️ **중첩 git 주의:** `pretty_four/`는 부모와 별개의 git 저장소다. Flutter 코드 변경은 `pretty_four/` 안에서 커밋하고, 그 후 부모에서 gitlink(`git add pretty_four`)를 갱신해 커밋한다.

## 3. 환경 설정

```bash
./init.sh          # Docker(백엔드+DB) 기동 + Flutter 의존성 설치까지 한 번에
```

수동 설정은 [README.md](./README.md) 참고. 필요 도구: Docker, Node 20(`backend/.nvmrc`), **Flutter 3.35.1**(Dart 3.9, pubspec `sdk: ^3.9.0`), Xcode/Android SDK. CI도 동일 버전으로 핀(`.github/workflows/ci.yml`).

비밀키는 `backend/.env`에 둔다(`backend/.env.example` 복사). **절대 커밋 금지**(gitignore됨). `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 필요.

## 4. Definition of Done (완료 기준)

코드 변경은 아래 명령이 **모두 통과**해야 "완료"다. 통과를 직접 실행해 확인하기 전에는 완료라고 주장하지 않는다.

| 영역 | 명령 | 통과 기준 |
|------|------|-----------|
| Flutter 정적분석 | `cd pretty_four && flutter analyze` | `No issues found!` |
| Flutter 테스트 | `cd pretty_four && flutter test` | `All tests passed!` (현재 13개) |
| 백엔드 타입체크 | `cd backend && npm run typecheck` | exit 0, 에러 없음 |
| 백엔드 빌드 | `cd backend && npm run build` | exit 0 |
| 백엔드 단위 테스트 | `cd backend && npm run test` | exit 0 (DB 불필요, mocked repo) |
| 백엔드 E2E | `cd backend && npm run test:e2e` | exit 0 (MariaDB 필요: `docker compose up -d db`) |
| 백엔드 기동 | `docker compose up -d --build backend` | `Server running on port 3000` |

> **3단계 종결 검증:** 정적(typecheck/build/analyze) → 런타임/행위(단위 테스트, flutter test) → E2E(`test:e2e` supertest로 실제 HTTP 201/200/401/409). AI 분석 파이프라인은 외부 키가 필요해 [docs/manual-ai-pipeline-check.md](./docs/manual-ai-pipeline-check.md)로 수동 검증한다.

기능별 검증 명령은 [`feature_list.json`](./feature_list.json)의 각 항목 `verification` 필드 참조.

## 5. 코딩 컨벤션

- **모델 키 매핑(중요):** 백엔드 엔티티 응답은 **camelCase**(TypeORM 기본). Flutter 모델 `fromJson`도 camelCase로 맞춘다. 단 `FeedbackItem`/`ConversationSummary`는 Claude가 생성한 JSON을 그대로 저장하므로 **snake_case**(`timestamp_sec`) 유지. 새 모델 추가 시 이 규칙을 지킨다.
- **커밋:** Conventional Commits (`feat`/`fix`/`docs`/`chore`/`refactor` + scope). 한국어 제목 허용.
- **Flutter:** 비즈니스 로직(서비스/네비게이션/상태)과 UI를 분리. 공통 UI는 `lib/widgets/app_widgets.dart`, 디자인 토큰은 `lib/core/theme.dart`.
- **백엔드:** 모듈 단위(`*.module.ts`/`*.service.ts`/`*.controller.ts`). 보호 라우트는 `JwtAuthGuard`. 검증은 DTO + `class-validator`.

> 위 **모델 키 매핑**과 **보호 라우트 가드** 불변식은 `scripts/arch-guard.sh`로 자동 강제된다(CI `arch-guard` job). 산문 규칙이 아니라 실행 가능 체크다 — `bash scripts/arch-guard.sh`로 로컬 확인.

## 6. 스코프 경계

- **포함(MVP):** 이메일/구글/카카오 로그인, **다중 아이 프로필(활성 아이 전환)**, 녹음→분석→결과, 히스토리.
- **제외(추후):** 네이버 로그인, 추세 그래프, 푸시 알림, 오디오 보관 옵션, 온디바이스 STT. (근거: [docs/superpowers/specs](./docs/superpowers/specs/))
- **다중 아이 설계:** [docs/superpowers/specs/2026-05-31-multi-child-design.md](./docs/superpowers/specs/2026-05-31-multi-child-design.md) (활성 아이는 서버 `User.activeChildId`에 저장, 삭제 cascade).

### 단일 활성 작업 (WIP=1)

동시에 진행 중인 기능은 **최대 1개**다. 새 작업을 시작하기 전에 이전 작업을 `pass`(검증 통과) 또는 `todo`(보류)로 종결한다. `feature_list.json`에서 `status: "wip"`이거나 `active: true`인 항목은 **항상 1개 이하**여야 한다(불변식). 여러 기능을 동시에 미완성으로 벌여두지 않는다 — 코드량보다 "끝난 작업"이 중요하다.

검증: `jq -e '[.features[] | select(.status=="wip")] | length <= 1' feature_list.json`

## 7. 더 읽기 (점진적 공개)

- 아키텍처·데이터 흐름 → [docs/HLD.md](./docs/HLD.md)
- API·DB 스키마·화면 상세 → [docs/LLD.md](./docs/LLD.md)
- 설계 의도·결정 → [docs/superpowers/specs/2026-05-30-child-coaching-design.md](./docs/superpowers/specs/2026-05-30-child-coaching-design.md)
- 현재 진행 상황 → [claude-progress.md](./claude-progress.md)
- 세션 핸드오프 → [session-handoff.md](./session-handoff.md)
- 커밋 전 점검 → [clean-state-checklist.md](./clean-state-checklist.md)
