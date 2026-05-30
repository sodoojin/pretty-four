# 진행 로그 (claude-progress.md)

> 작업 단위로 추가. 최신 항목이 위. "완료"는 검증 명령 통과를 확인한 경우만.

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
