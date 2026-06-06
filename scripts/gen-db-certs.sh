#!/bin/bash
# MariaDB SSL용 자체 서명 CA + 서버 인증서 생성. 한 번만 실행.
# 출력: db/certs/{ca.crt, server.crt, server.key}
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$PROJECT_DIR/db/certs"
DAYS=3650   # 10년

if [ -f "$CERT_DIR/server.crt" ] && [ -f "$CERT_DIR/server.key" ] && [ -f "$CERT_DIR/ca.crt" ]; then
	echo "이미 인증서가 존재합니다: $CERT_DIR"
	echo "재생성하려면 디렉터리를 먼저 삭제하세요: rm -rf $CERT_DIR"
	exit 0
fi

mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "==> CA 키/인증서 생성"
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days "$DAYS" \
	-out ca.crt -subj "/CN=pretty-four-db-ca"

echo "==> 서버 키/CSR 생성"
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
	-subj "/CN=pretty-four-db"

echo "==> 서버 인증서 서명 (CA로)"
cat > server.ext <<EOF
subjectAltName = DNS:db, DNS:localhost, IP:127.0.0.1
EOF
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
	-out server.crt -days "$DAYS" -sha256 -extfile server.ext

rm -f server.csr server.ext ca.srl ca.key
# CA 키는 더 이상 필요 없음 (인증서 재발급 안 할 거면). 보관하려면 위 줄 제거.

# MariaDB가 컨테이너 안에서 읽을 수 있게 권한
chmod 644 ca.crt server.crt
chmod 600 server.key

echo ""
echo "==> 완료. 파일:"
ls -la "$CERT_DIR"
echo ""
echo "다음 단계: docker compose up -d db"
