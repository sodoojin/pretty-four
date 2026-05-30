# 세션 핸드오프 (session-handoff.md)

> 다음 세션/에이전트가 즉시 이어받기 위한 현재 상태 스냅샷. 작업 종료 시 갱신.

**최종 갱신:** 2026-05-30

## 지금 어디까지 됐나
- MVP 기능 전부 구현 + 소프트 파스텔 디자인 적용 완료.
- 백엔드(NestJS+MariaDB) Docker로 동작, AI 파이프라인 E2E 확인됨(샘플 음성).
- 하네스 아티팩트(AGENTS/README/init.sh/feature_list/progress/handoff/clean-state) 정비 완료.
- 모든 DoD 검증 통과: `flutter analyze`, `flutter test`(13), `npm run check`.

## 환경
- git 저장소 2개: 부모 `pretty-four`(백엔드·문서), 중첩 `pretty_four`(Flutter). 둘 다 `main`.
- 백엔드 비밀키는 `backend/.env`(gitignore). 앱은 `pretty_four/.env`의 `API_BASE_URL`로 백엔드 접속.
- 실행: `./init.sh` → `cd pretty_four && flutter run`.

## 바로 알아야 할 함정
- **중첩 git:** Flutter 변경은 `pretty_four/`에서 커밋 후, 부모에서 `git add pretty_four`로 gitlink 갱신.
- **모델 키 매핑:** 엔티티=camelCase, Claude 생성 JSON(`FeedbackItem.timestamp_sec`)=snake_case. 혼동 시 저장/파싱 실패(`Null is not a subtype of String`).
- **시뮬레이터 파일 선택:** iOS 시뮬레이터 Files 앱은 비어 있어 파일 선택 테스트가 어렵다. 파일을 드래그로 넣거나 실기기 사용.
- `FileType.audio`는 iOS에서 선택기가 안 열림 → `FileType.custom`+allowedExtensions 사용 중.

## 다음 작업 후보 (우선순위)
1. 소셜 로그인 실기기 E2E (키 설정 필요).
2. 백엔드 통합 테스트 + CI(.github/workflows)로 DoD 자동화.
3. 견고성: 폴링 타임아웃, 업로드 중단 복구.

## 미해결/리스크
- 운영 전환 필요 설정: 백엔드 `enableCors({origin:'*'})`, TypeORM `synchronize:true` → 운영에선 제한/마이그레이션으로.
- AI 분석은 외부 API 키·과금 의존(Whisper 분당 $0.006, Claude 토큰 과금).
