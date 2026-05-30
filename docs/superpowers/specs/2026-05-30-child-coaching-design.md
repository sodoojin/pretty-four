# 아이 훈육 코칭 앱 — 설계 문서

**날짜:** 2026-05-30  
**상태:** 승인됨  
**플랫폼:** Flutter (iOS / Android)

---

## 1. 서비스 개요

부모가 아이와의 일상 대화를 녹음하면, AI가 대화를 분석해 연령에 맞는 훈육 코칭을 제공하는 모바일 앱.

**핵심 가치:**
- 녹음 → 분석 → 코칭까지 앱 하나로 완결
- 아이의 나이에 맞춘 발달 심리 기반 피드백
- 개인정보 보호: 오디오 파일은 분석 후 즉시 삭제

**목표:** MVP 출시 후 사용자 반응을 보고 확장 여부 결정

---

> **업데이트 노트 (2026-05-30):** 초기 설계는 Supabase(Auth/Storage/Edge Functions/PostgreSQL) 기반이었으나, 구현 단계에서 **자체 NestJS + MariaDB 백엔드(Docker Compose)**로 전환했다. 추후 개인 서버 이전 시 유연성과 데이터 소유권 확보가 목적이다. 아래 내용은 실제 구현 기준으로 갱신했다. 구현 상세는 [HLD.md](../../HLD.md), [LLD.md](../../LLD.md) 참고.

## 2. 기술 스택

| 레이어 | 기술 |
|--------|------|
| 앱 | Flutter (Dart) |
| 백엔드 | NestJS 10 (REST API) |
| 인증 | 자체 JWT 인증 (이메일/구글/카카오; 네이버는 MVP 이후) |
| 스토리지 | 서버 로컬 디스크 (오디오 임시 보관, Docker 볼륨) |
| DB | MariaDB 11 (TypeORM) |
| 배포 | Docker Compose (backend + db) |
| STT | OpenAI Whisper API |
| 분석/코칭 | Anthropic Claude API |

---

## 3. 아키텍처

```
[Flutter 앱]
      │ HTTPS (REST + JWT)
      ▼
[NestJS 백엔드]  (Docker)
  ├── Auth 모듈 (이메일/구글/카카오 → JWT 발급)
  ├── Children / Sessions 모듈 (프로필·세션 관리)
  ├── Analysis 모듈 (AI 파이프라인 실행)
  ├── 로컬 디스크 (오디오 임시 업로드)
  └── MariaDB (TypeORM, 결과 저장)
      │
      ├── OpenAI Whisper API (음성 → 텍스트)
      └── Claude API (텍스트 → 코칭 분석)
```

**처리 흐름:**
1. 앱에서 오디오 녹음 후 `POST /sessions/upload`로 백엔드에 업로드 (multipart)
2. 백엔드가 세션을 `processing`으로 생성하고 백그라운드 분석 시작 → Whisper API 호출 (STT)
3. 전사 텍스트 + 아이 나이(개월) → Claude API 호출 (분석)
4. 분석 결과를 MariaDB에 저장, 세션 상태를 `completed`로 갱신
5. 로컬 디스크에서 오디오 파일 즉시 삭제 (성공/실패 무관)
6. 앱이 `GET /sessions/:id` 폴링으로 완료 확인 후 `GET /sessions/:id/result`로 결과 조회

**예상 처리 시간:** 5분 녹음 기준 약 20~40초

---

## 4. 화면 구성

```
인트로(온보딩)  ← 최초 1회만, 감정 스토리텔링(비→맑음)
  └── 로그인 화면 (카카오 / 구글 / 이메일; 네이버는 MVP 이후)
  └── 아이 프로필 등록 (이름, 생년월일)

[하단 탭바: 홈 / 녹음시작(중앙 강조) / 설정]
홈 탭
  └── 인사 + "대화 녹음 시작" CTA 카드
  └── 최근 분석 기록 목록
녹음시작(중앙 버튼)
  └── 녹음 화면(파형·일시정지·중지·시간) → 분석 중 → 결과
설정 탭
  └── 아이 프로필
  └── 전체 기록(날짜별 분석 기록)
  └── 로그아웃

녹음 화면        └── 파형 시각화 / 일시정지·중지 / 녹음 시간
분석 중 화면      └── 로딩 애니메이션 / 단계별 진행 메시지
결과 화면        ├── 요약 리포트(분위기·패턴·개선 포인트) └── 타임스탬프별 피드백
```

> 네비게이션: 하위 화면(녹음/결과/기록)은 모두 push로 띄워 뒤로가기 일관성을 보장한다. 녹음→분석→결과는 pushReplacement로 연결되어, 결과에서 뒤로가면 메인 탭으로 복귀한다.

### 4.1 인트로(온보딩) — 감정 스토리텔링

**목적:** 로그인 전, 앱의 가치를 감정적으로 전달. "육아의 답답함(비) → 코칭으로 개임(맑음)" 메타포.

**노출 정책:** **최초 실행 1회만**(로컬 플래그 저장). 이후 실행에서는 바로 로그인으로. 항상 **건너뛰기** 버튼 제공, **탭하면 다음 비트**로 진행.

**연출:** 흐린 유리창에 빗방울이 흐르다가(블루그레이, blur 높음) → 점차 비가 개고 창 너머가 맑아짐(민트→블루, blur 0). 텍스트는 비트별 페이드.

**스크립트(비트):**

| # | 화면 상태 | 카피 |
|---|-----------|------|
| 1 | 흐림·비 내림 | "육아, 매일이 쉽지 않으시죠" |
| 2 | 흐림·비 내림 | "할 일은 많은데, 아이는 내 맘 같지 않고" |
| 3 | 흐림·비 내림 | "화내고 돌아서서 미안했던 적, 누구나 있어요" |
| 4 | 개임·밝아짐 | "발달심리에 기반해, 아이 나이에 꼭 맞는 코칭을 담았어요" |
| 5 | 맑음 | "대화를 들려주세요. 아이 마음에 닿는 말을 함께 찾을게요" |
| → | CTA | **[시작하기]** → 로그인 |

**카피 원칙:**
- **정직성:** "N명의 전문가" 같은 검증 불가한 주장 금지. 실제 구현(발달심리 기반 연령별 AI 코칭)에 부합하는 표현만 사용.
- **정상화:** 부모를 탓하지 않고 "누구나 그래요"로 공감.
- **착지:** 막연한 위로 대신 앱의 핵심 약속(대화→맞춤 코칭)으로 마무리해 로그인으로 자연 연결.

---

## 5. 데이터 모델

> MariaDB(TypeORM) 기준. 컬럼명은 TypeORM 엔티티의 camelCase를 그대로 사용한다(앱 모델 키도 이에 맞춤). JSON 컬럼(summary/feedbacks)은 Claude 응답을 그대로 저장하므로 내부 키는 snake_case 유지.

```
-- 사용자 (users)
  id           uuid PK
  email        varchar  unique, nullable
  password     varchar  nullable (bcrypt 해시, select:false)
  provider     enum     (email | google | kakao)
  providerId   varchar  nullable (소셜 고유 ID)
  createdAt    datetime

-- 아이 프로필 (children)
  id           uuid PK
  userId       varchar  FK → users.id
  name         varchar
  birthDate    date
  createdAt    datetime

-- 분석 세션 (sessions)
  id           uuid PK
  childId      varchar  FK → children.id
  userId       varchar
  audioPath    varchar  nullable (분석 후 null)
  durationSec  int      default 0
  status       enum     (processing | completed | failed)
  recordedAt   datetime

-- 분석 결과 (analysis_results)
  id              uuid PK
  sessionId       varchar  FK → sessions.id (1:1)
  summary         json
  feedbacks       json
  rawTranscript   text     nullable
  childAgeMonths  int
  createdAt       datetime
```

**feedbacks JSON 구조:**
```json
[
  {
    "timestamp_sec": 42,
    "original": "하지 말라고 했잖아!",
    "suggestion": "지금 ~하면 안 된다고 느끼는구나. 같이 해결해볼까?",
    "reason": "명령형보다 감정 반영 후 대안 제시가 효과적이에요."
  }
]
```

**summary JSON 구조:**
```json
{
  "tone": "지시적",
  "patterns": ["명령형 발화 다수", "칭찬 부족"],
  "improvements": ["감정 반영 먼저", "선택지 제공"]
}
```

---

## 6. AI 파이프라인 상세

### STT (Whisper API)
- 입력: m4a 또는 wav 오디오
- 출력: 타임스탬프 포함 전사 텍스트
- 비용: $0.006/분 (5분 녹음 ≈ $0.03)

### 분석 (Claude API)
- 입력: 전사 텍스트 + 아이 나이(개월)
- 출력: summary + feedbacks JSON

**연령별 프롬프트 전략:**

| 나이 | 코칭 방향 |
|------|-----------|
| 만 2~3세 | 단순하고 일관된 지시, 짧은 문장 권장 |
| 만 4~6세 | 선택지 제공, 규칙 이유 설명 |
| 만 7~10세 | 논리적 설명, 감정 공감 우선 |
| 만 11세+ | 자율성 존중, 협상과 타협 |

---

## 7. 에러 처리

| 상황 | 처리 방식 |
|------|-----------|
| 녹음 중 앱 백그라운드 전환 | 백그라운드 오디오 권한으로 녹음 유지 |
| 업로드 실패 (네트워크) | 로컬 임시 저장 후 재시도 |
| Whisper API 오류 | 사용자에게 실패 안내, session.status → failed |
| Claude API 오류 | 동일하게 실패 처리, 오디오 즉시 삭제 |
| 처리 30초 이상 소요 | 진행 메시지 업데이트 ("거의 다 됐어요") |

---

## 8. 테스트 전략

**Unit 테스트**
- 연령 계산 로직 (생년월일 → 개월수)
- Claude 응답 JSON 파싱 → feedbacks 모델 변환

**Integration 테스트**
- 자체 JWT 인증 + 소셜 로그인(구글/카카오) 연동
- 백엔드 Analysis 모듈 전체 파이프라인 (Whisper + Claude 실제 API 호출)

**수동 테스트 (MVP)**
- 실제 대화 녹음 5건으로 코칭 품질 검증
- iOS / Android 각 1기기 이상

---

## 9. MVP 범위

**포함:**
- 카카오 / 구글 / 이메일 로그인
- 단일 아이 프로필
- 녹음 → 분석 → 결과 전체 흐름
- 히스토리 목록

**MVP 이후 추가 검토:**
- 네이버 로그인
- 다중 아이 프로필
- 히스토리 추세 그래프
- 푸시 알림
- 오디오 보관 선택 옵션
- 온디바이스 STT 전환
