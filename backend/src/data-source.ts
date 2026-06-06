import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { User } from './users/entities/user.entity';
import { Child } from './children/entities/child.entity';
import { Session } from './sessions/entities/session.entity';
import { AnalysisResult } from './analysis/entities/analysis-result.entity';

/**
 * TypeORM CLI(마이그레이션 생성/실행)용 DataSource.
 * 런타임 앱은 app.module.ts의 forRootAsync 설정을 사용한다 — 엔티티 목록을 동일하게 유지할 것.
 * ts-node CLI에서는 __dirname=src, 컴파일 후(node dist)에는 __dirname=dist 로 글롭이 맞춰진다.
 */
export default new DataSource({
  type: 'mariadb',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number(process.env.DB_PORT ?? 3306),
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  charset: 'utf8mb4',
  entities: [User, Child, Session, AnalysisResult],
  migrations: [__dirname + '/migrations/*.{ts,js}'],
});
