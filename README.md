# 이쁜네살 (Pretty Four)

부모와 아이의 대화를 녹음·분석해 **연령별 훈육 코칭**을 제공하는 모바일 앱.

- **앱:** Flutter (iOS/Android) — `pretty_four/`
- **백엔드:** NestJS + MariaDB (Docker) — `backend/`
- **AI:** OpenAI Whisper(STT) + Anthropic Claude(코칭 분석)

> 🤖 AI 에이전트로 작업한다면 먼저 **[AGENTS.md](./AGENTS.md)**를 읽으세요 (진입 문서·완료 기준·컨벤션).

## 빠른 시작

```bash
# 0) 사전 준비: Docker, Node 20, Flutter 3.9+
cp backend/.env.example backend/.env   # OPENAI_API_KEY, ANTHROPIC_API_KEY 채우기

# 1) 한 번에 셋업 (백엔드+DB 기동, Flutter 의존성 설치)
./init.sh

# 2) 앱 실행 (시뮬레이터/기기)
cd pretty_four && flutter run
```

백엔드는 `http://localhost:3000`. 앱의 `pretty_four/.env`에 `API_BASE_URL=http://localhost:3000`.

## 배포 (운영)

운영 백엔드는 **맥미니 + Cloudflare Tunnel** 구성으로 자가 호스팅 중입니다.

- **API 엔드포인트:** `https://pretty-four.sprout-labs.kr`
- **구조:** 앱 → Cloudflare 엣지(ICN) → cloudflared(맥미니) → Caddy → NestJS blue/green (Docker) → MariaDB(127.0.0.1)
- **무중단 배포 (zero-downtime):** Caddy가 `/health` 기반으로 healthy 인스턴스에만 라우팅. blue → green 순차 재생성으로 사용자 다운타임 0초. 배포는 `./scripts/deploy.sh`
- **자동 복구:** 정전 후 자동 부팅 → 자동 로그인 → Docker 자동 기동 → 터널 launchd 자동 재연결
- **보안:** DB는 호스트 외부 비노출, `.env`는 git 미추적, FileVault는 의도적으로 끈 상태(운영 편의 우선)
- **스키마 관리:** `NODE_ENV=production`이라 TypeORM `synchronize` OFF · 부팅 시 마이그레이션 자동 적용(`migrationsRun`). 엔티티 변경 → `npm run migration:generate` → git push → 맥미니에서 `git pull && ./scripts/deploy.sh`

상세 절차·트러블슈팅·운영 점검 체크리스트는 [docs/deploy/mac-mini-cloudflare-tunnel.md](./docs/deploy/mac-mini-cloudflare-tunnel.md) 참고.

## 검증 (Definition of Done)

```bash
cd pretty_four && flutter analyze && flutter test   # 정적분석 + 13 테스트
cd backend && npm run typecheck && npm run build     # 타입체크 + 빌드
```

자세한 기준은 [AGENTS.md §4](./AGENTS.md), 기능별 검증은 [feature_list.json](./feature_list.json).

## 문서

| 문서 | 내용 |
|------|------|
| [AGENTS.md](./AGENTS.md) | 에이전트 진입 문서 (완료 기준·컨벤션·구조) |
| [docs/HLD.md](./docs/HLD.md) | 고수준 설계 (아키텍처·데이터 흐름) |
| [docs/LLD.md](./docs/LLD.md) | 상세 설계 (API·스키마·화면) |
| [docs/design/preview.html](./docs/design/preview.html) | UI 디자인 시안 |
| [docs/deploy/mac-mini-cloudflare-tunnel.md](./docs/deploy/mac-mini-cloudflare-tunnel.md) | 운영 배포 가이드 (맥미니 + Cloudflare Tunnel) |

## 라이선스

비공개 프로젝트.
