// E2E 테스트 환경변수 기본값. AppModule(TypeOrmModule/JwtModule)이 로드되기 전에 실행된다(jest setupFiles).
// 로컬: docker compose up -d db 의 기본값과 일치. CI: mariadb 서비스가 동일 값을 주입한다.
import { tmpdir } from 'os';
import { join } from 'path';

// sessions.controller의 diskStorage가 모듈 로드 시 디렉터리를 mkdir하므로 쓰기 가능한 경로가 필요하다.
process.env.UPLOAD_DIR = process.env.UPLOAD_DIR || join(tmpdir(), 'pretty-four-test-uploads');
process.env.DB_HOST = process.env.DB_HOST || '127.0.0.1';
process.env.DB_PORT = process.env.DB_PORT || '3306';
process.env.DB_USER = process.env.DB_USER || 'app';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || 'apppass';
process.env.DB_NAME = process.env.DB_NAME || 'pretty_four';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
