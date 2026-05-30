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

## 2. 기술 스택

| 레이어 | 기술 |
|--------|------|
| 앱 | Flutter (Dart) |
| 인증 | Supabase Auth (카카오, 구글, 이메일; 네이버는 MVP 이후) |
| 스토리지 | Supabase Storage (오디오 임시 보관) |
| 서버리스 | Supabase Edge Functions (AI 파이프라인) |
| DB | Supabase PostgreSQL |
| STT | OpenAI Whisper API |
| 분석/코칭 | Anthropic Claude API |

---

## 3. 아키텍처

```
[Flutter 앱]
      │ HTTPS
      ▼
[Supabase]
  ├── Auth (소셜 로그인)
  ├── Storage (오디오 임시 업로드)
  ├── Edge Function (AI 파이프라인 실행)
  └── PostgreSQL (결과 저장)
      │
      ├── OpenAI Whisper API (음성 → 텍스트)
      └── Claude API (텍스트 → 코칭 분석)
```

**처리 흐름:**
1. 앱에서 오디오 녹음 후 Supabase Storage에 업로드
2. Edge Function이 트리거되어 Whisper API 호출 (STT)
3. 전사 텍스트 + 아이 나이 → Claude API 호출 (분석)
4. 분석 결과를 PostgreSQL에 저장
5. Storage에서 오디오 파일 즉시 삭제
6. 앱에 결과 반환

**예상 처리 시간:** 5분 녹음 기준 약 20~40초

---

## 4. 화면 구성 (6개)

```
온보딩
  └── 로그인 화면 (카카오 / 네이버 / 구글 / 이메일)
  └── 아이 프로필 등록 (이름, 생년월일)

홈 화면
  └── 최근 분석 기록 목록
  └── "대화 녹음 시작" CTA 버튼

녹음 화면
  └── 파형 시각화
  └── 일시정지 / 중지 버튼
  └── 녹음 시간 표시

분석 중 화면
  └── 로딩 애니메이션
  └── 단계별 진행 메시지

결과 화면
  ├── 요약 리포트 (대화 분위기, 패턴, 개선 포인트)
  └── 구체적 피드백 (타임스탬프별 발화 + 개선 제안)

히스토리 화면
  └── 날짜별 분석 기록 목록
```

---

## 5. 데이터 모델

```sql
-- 사용자
users
  id          uuid PK
  email       text
  provider    text  (kakao | naver | google | email)
  created_at  timestamp

-- 아이 프로필
children
  id          uuid PK
  user_id     uuid FK → users
  name        text
  birth_date  date
  created_at  timestamp

-- 분석 세션
sessions
  id           uuid PK
  child_id     uuid FK → children
  recorded_at  timestamp
  duration_sec int
  status       text  (processing | completed | failed)

-- 분석 결과
analysis_results
  id               uuid PK
  session_id       uuid FK → sessions
  summary          jsonb
  feedbacks        jsonb
  raw_transcript   text
  child_age_months int
  created_at       timestamp
```

**feedbacks JSONB 구조:**
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

**summary JSONB 구조:**
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
- Supabase Auth 소셜 로그인 연동
- Edge Function 전체 파이프라인 (실제 API 호출)

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
