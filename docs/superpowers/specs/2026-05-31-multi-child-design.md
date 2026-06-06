# 다중 아이(Multiple Children) 설계 — 2026-05-31

## 배경
현재 앱은 "현재 아이 1명" 가정(`GET /children/current` = 가장 오래된 1명). 저장은 이미 다대일이라 다중 보관은 가능하나 API·UI·라우팅이 단일 아이 전제. 업로드 시 나이 계산이 `findCurrent`(첫 아이)로 하드코딩돼 **다중 아이면 선택한 아이가 아닌 첫 아이 나이로 분석되는 버그** 존재.

> `AGENTS.md §6`에서 "다중 아이"는 기존 제외(추후) 스코프 → 본 작업으로 MVP 스코프 확장.

## 결정 사항 (협의 완료)
- **아이 먼저 선택 후 녹음/분석.** 선택한 아이는 "활성 아이"로 기억, 녹음 흐름은 활성 아이 기준.
- **활성 아이는 서버 저장** (`User.activeChildId`, nullable). 멀티기기 일관성 확보.
- **풀 CRUD + 활성 전환** (목록·추가·수정·삭제·전환).
- **히스토리는 활성 아이만** 표시 (`GET /sessions?childId=`).
- **삭제는 cascade**: 아이 삭제 시 그 아이의 sessions + analysis_results 함께 삭제(트랜잭션) + "정말 삭제?" 확인.
- 범위 밖(YAGNI): 아이 수 제한, 아바타/사진, 추세 그래프.

## 분할: 2개 작업 (백엔드 선행 → Flutter)

### 작업 1 — 백엔드: 다중 아이 API + 활성 아이 + 업로드 정확성
- `User.activeChildId`(varchar nullable) 컬럼 추가.
- `GET /children` — 사용자의 아이 목록(생성순, camelCase).
- `GET /children/active` — 활성 아이 반환(없으면 첫 아이 폴백 또는 null).
- `PUT /children/active` `{ childId }` — 활성 아이 설정(소유권 검증, 타인/없는 아이 → 404/403).
- `POST /children` — 생성 시 활성 아이가 없으면 새 아이를 활성으로.
- `DELETE /children/:id` — 소유권 확인 후 트랜잭션 cascade(`analysis_results` → `sessions` → `child`). 삭제 대상이 활성이면 남은 첫 아이로 재지정, 0명이면 null.
- `POST /sessions/upload` 수정 — 나이 계산을 **요청 childId로 조회한 아이**(소유권 검증)로. `findCurrent` 의존 제거.
- `GET /sessions?childId=` — 활성 아이 스코프 필터(소유권 검증).
- `GET /children/current` — 신규 코드 미사용(하위호환용으로 일시 유지, 후속 제거).
- 모델 키 camelCase 유지(arch-guard).

### 작업 2 — Flutter: 다중 아이 UI + 활성 전환 (작업 1 선행)
- `ChildService`: `getChildren()`, `getActiveChild()`, `setActiveChild(id)`, `updateChild(...)`, `deleteChild(id)`.
- 아이 관리 화면(설정 진입): 목록·추가·수정·삭제·활성 선택.
- 홈 헤더 아이 전환기(이름 탭 → 바텀시트에서 전환/추가).
- 라우터: `getCurrentChild` → 활성/목록 기반. 0명이면 `/profile-setup`(기존 온보딩 재사용).
- 업로드 시 활성 childId 전송(processing_screen).
- 히스토리 활성 아이 스코프(`GET /sessions?childId=`).

## 검증 (DoD)
- 백엔드: `npm run test:e2e` — 목록/active 설정·조회/삭제 cascade(세션·결과 0건)/upload가 전달 childId 나이로 분석/`?childId=` 필터; `npm run check`; `arch-guard`.
- Flutter: `flutter analyze`/`flutter test` — Child 목록 파싱·활성 전환·라우팅.

## 의존성
- 작업 2는 작업 1의 API에 의존. 작업 1 먼저 머지/검증 후 작업 2.
