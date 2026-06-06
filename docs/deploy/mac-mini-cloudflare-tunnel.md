# 맥미니 + Cloudflare Tunnel 배포 가이드

> "이쁜네살" 백엔드(NestJS + MariaDB, Docker)를 **맥미니에서 운영**하고, **Cloudflare Tunnel**로 공인 IP·포트포워딩 없이 HTTPS 공개하는 방법.
> CGNAT 환경에서도 동작하며, 인바운드 포트를 열지 않아 안전합니다.

**전체 그림**
```
[모바일 앱] ──HTTPS──> [Cloudflare 엣지] ──암호화 터널──> [cloudflared(맥미니)] ──http──> [localhost:3000 백엔드(Docker)]
                                                                                            └── MariaDB(Docker, 내부망)
```

---

## 0. 사전 준비물

- 항상 켜둘 **맥미니** (Apple Silicon 권장, RAM 8GB+)
- **Cloudflare 계정**(무료) + **본인 소유 도메인**(현재: `sprout-labs.kr`, 백엔드 서브도메인 `pretty-four.sprout-labs.kr`) — 도메인을 Cloudflare에 등록(네임서버 이전)해 둘 것
- 프로젝트 코드(이 저장소)
- 백엔드 API 키: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`

> 도메인이 아직 없다면: 테스트는 `cloudflared tunnel --url http://localhost:3000` (TryCloudflare, 임시 랜덤주소)로 먼저 확인 가능. 운영은 도메인 필요.

---

## 1. 맥미니에 Docker 설치

Docker Desktop보다 가벼운 **OrbStack** 추천(개인 무료):

```bash
# Homebrew 없으면 먼저 설치: https://brew.sh
brew install orbstack
# OrbStack 앱 실행 → docker CLI 자동 사용 가능
docker version   # 확인
```

대안: `brew install --cask docker` (Docker Desktop) 또는 `brew install colima docker docker-compose && colima start`.

---

## 2. 코드 가져오기 + 환경변수

```bash
# 맥미니에서 (예: 홈 디렉터리)
cd ~
git clone <이 저장소 URL> pretty-four    # 또는 코드를 복사
cd pretty-four

# 백엔드 비밀키 설정
cp backend/.env.example backend/.env

# Docker Compose도 같은 .env를 참조하도록 프로젝트 루트에 심볼릭 링크
# (없으면 compose가 DB 비밀번호를 기본 fallback 값으로 읽어 접속 실패함)
ln -sf backend/.env .env
```

`backend/.env`를 편집해 **운영값**으로 채웁니다:

```dotenv
DB_NAME=pretty_four
DB_USER=app
DB_PASSWORD=<강력한_DB_비밀번호>
DB_ROOT_PASSWORD=<강력한_root_비밀번호>

# production → synchronize 꺼지고 마이그레이션 자동 적용(app.module migrationsRun).
NODE_ENV=production
# 웹 클라이언트를 붙일 때만 도메인 제한(쉼표 구분). 모바일 전용이면 생략 가능(미설정=전체 허용).
CORS_ORIGINS=https://pretty-four.sprout-labs.kr

JWT_SECRET=<openssl rand -base64 48 로 생성한 긴 랜덤값>
JWT_EXPIRES_IN=7d

OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

GOOGLE_CLIENT_ID=...        # 구글 로그인 쓸 때
UPLOAD_DIR=/app/uploads
```

JWT 시크릿 생성 예시:
```bash
openssl rand -base64 48
```

---

## 3. DB 포트 노출 범위 (기본 안전)

`docker-compose.yml`의 MariaDB는 `127.0.0.1:3306` (loopback)에만 바인딩됩니다. 호스트 외부 IP에는 노출되지 않으므로 **운영에서 별도 수정이 필요하지 않습니다.**

- 맥미니 자체에서만 DB GUI 툴(TablePlus 등)로 `localhost:3306` 접근 가능
- 외부망/LAN에서는 DB 포트로 직접 접근 불가
- 백엔드는 컨테이너 내부망(`db:3306`)으로 접근하므로 영향 없음
- cloudflared는 `localhost:3000` (백엔드)만 외부에 공개

---

## 4. 백엔드 + DB 기동

```bash
cd ~/pretty-four
docker compose up -d --build
# 상태 확인
docker compose ps
docker compose logs -f backend     # "Server running on port 3000" 확인 후 Ctrl-C
```

헬스 체크:
```bash
curl -i -X POST http://localhost:3000/auth/login -H "Content-Type: application/json" -d '{}'
# 400(검증 실패) 또는 401 이면 정상 동작
```

`restart: unless-stopped`가 설정되어 있어, 재부팅 후 Docker가 뜨면 컨테이너도 자동 재시작됩니다.

---

## 5. Cloudflare Tunnel 설정

### 5-1. cloudflared 설치 & 로그인
```bash
brew install cloudflared
cloudflared tunnel login        # 브라우저 열림 → 도메인 선택/인증
```

### 5-2. 터널 생성
```bash
cloudflared tunnel create pretty-four
# → 터널 ID 출력 + ~/.cloudflared/<TUNNEL_ID>.json (자격증명) 생성
cloudflared tunnel list         # 생성 확인
```

### 5-3. 설정 파일 작성
`~/.cloudflared/config.yml` 생성:

```yaml
tunnel: <TUNNEL_ID>
credentials-file: /Users/<사용자명>/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: pretty-four.sprout-labs.kr      # 원하는 서브도메인
    service: http://localhost:3000
  - service: http_status:404
```

### 5-4. DNS 라우팅 연결
```bash
cloudflared tunnel route dns pretty-four pretty-four.sprout-labs.kr
# → Cloudflare DNS에 pretty-four.sprout-labs.kr → 터널 CNAME 자동 추가
```

### 5-5. 동작 테스트
```bash
cloudflared tunnel run pretty-four
# 다른 터미널/외부에서:
curl -i https://pretty-four.sprout-labs.kr/auth/login -X POST -H "Content-Type: application/json" -d '{}'
# 400/401 이면 외부에서 HTTPS로 백엔드까지 정상 연결됨
```
확인되면 Ctrl-C로 중지하고 다음 단계(서비스 등록)로.

### 5-6. 상시 서비스로 등록 (재부팅 자동 시작)
```bash
sudo cloudflared service install
# launchd 데몬으로 등록되어 부팅 시 자동 실행 (config.yml 사용)
# 상태:
sudo launchctl list | grep cloudflared
```

---

## 6. 맥미니 상시 가동 설정

```bash
# 절전 비활성화
sudo systemsetup -setcomputersleep Never
sudo pmset -a sleep 0
sudo pmset -a disksleep 0
# 정전 복구 후 자동 부팅
sudo pmset -a autorestart 1
```

- **시스템 설정 → 에너지**: "정전 후 자동으로 다시 시작" 체크, 절전 해제.
- Docker가 로그인 세션을 요구하면(OrbStack/Docker Desktop) **자동 로그인** 활성화: 시스템 설정 → 사용자 및 그룹 → 자동 로그인.
  - 완전 헤드리스(로그인 없이)로 운영하려면 **Colima + launchd** 구성을 권장.
- macOS 자동 업데이트로 재부팅될 수 있음 → 업데이트는 수동/예약 시간대로.

---

## 7. 앱(Flutter)에서 서버 주소 전환

`pretty_four/.env`의 `API_BASE_URL`을 터널 도메인으로 변경:

```dotenv
API_BASE_URL=https://pretty-four.sprout-labs.kr
```

- 이제 실제 HTTPS이므로 **iOS ATS 예외(`NSAllowsLocalNetworking`)는 불필요**합니다. `ios/Runner/Info.plist`에서 해당 블록을 제거해도 됩니다(개발 중 localhost를 계속 쓸 거면 유지).
- 변경 후 앱 재빌드/배포.

---

## 8. 운영 점검 체크리스트

- [ ] `docker compose ps` — backend/db **Up**
- [ ] `curl https://pretty-four.sprout-labs.kr/auth/login` → 400/401 (외부에서 접속됨)
- [ ] DB 포트(3306)는 `127.0.0.1`에만 바인딩 — 호스트 외부 IP에는 노출 X (3단계)
- [ ] `backend/.env` 비밀키 설정 + git 미포함(`.gitignore`)
- [ ] 맥미니 절전 해제 + 정전 자동 부팅
- [ ] cloudflared 서비스 등록(재부팅 자동 시작)

---

## 9. MariaDB 백업 (권장)

데이터는 `db_data` 볼륨에 저장됩니다. 정기 백업:

```bash
# 덤프 백업
docker compose exec db sh -c \
  'exec mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" pretty_four' > backup_$(date +%Y%m%d).sql
```

`cron`이나 `launchd`로 매일 자동 백업 + 외부(클라우드 드라이브 등) 복사를 권장합니다.

---

## 10. 스키마 마이그레이션 & CORS (DJS-12에서 적용됨)

- **TypeORM 마이그레이션**: `NODE_ENV=production`이면 synchronize가 꺼지고 스키마를 마이그레이션으로 관리하며, **부팅 시 `migrationsRun`으로 자동 적용**됩니다(초기 마이그레이션 `src/migrations/*-Init.ts` 포함). 엔티티 변경 시:
  ```bash
  # 새 DB 변경분 마이그레이션 생성(개발 머신, DB 연결 필요)
  npm run migration:generate src/migrations/<이름>
  # 수동 적용(운영에선 컨테이너 부팅 시 자동)
  npm run migration:run
  ```
  > ⚠️ **이미 `synchronize:true`로 만든 기존 DB**에 마이그레이션을 처음 도입할 때는, 테이블이 이미 있어 Init 마이그레이션이 충돌합니다. 출시 전(실데이터 없음)이라면 **DB를 비우고 새로** 시작하는 게 가장 깔끔합니다. 실데이터가 있으면 `migrations` 테이블에 Init을 "적용됨"으로 수동 기록(fake)하세요.
- **CORS**: `CORS_ORIGINS`(쉼표 구분)으로 제한합니다. 미설정 시 전체 허용(개발). 모바일 전용이면 CORS는 영향이 적지만, 웹 클라이언트가 있으면 도메인을 지정하세요.
- **가용성**: 가정 회선·정전·macOS 업데이트로 일시 중단될 수 있음(무중단 보장 어려움). 사용자가 늘면 클라우드(Lightsail/NHN 등)로 이전 검토 — Docker Compose라 이전이 쉬움.
- **비용**: 서버비 0원이지만 Whisper(분당 $0.006)·Claude 토큰 과금은 사용량만큼 발생.

---

## 부록 A. 자주 쓰는 명령

```bash
docker compose up -d --build      # 빌드 후 기동
docker compose restart backend    # 백엔드 재시작
docker compose logs -f backend    # 로그
docker compose down               # 중지(볼륨 유지)
cloudflared tunnel list           # 터널 목록
sudo launchctl list | grep cloudflared   # 터널 서비스 상태
```

## 부록 B. 도메인 없이 빠른 테스트 (TryCloudflare)

```bash
# 백엔드가 localhost:3000에 떠 있는 상태에서
cloudflared tunnel --url http://localhost:3000
# → https://<랜덤>.trycloudflare.com 발급 (임시, 매번 바뀜). 앱 .env에 잠깐 넣어 테스트용.
```
