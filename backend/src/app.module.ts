import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import { CorrelationIdMiddleware } from './common/logging/correlation-id.middleware';
import { LoggingInterceptor } from './common/logging/logging.interceptor';
import { HealthController } from './health/health.controller';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ChildrenModule } from './children/children.module';
import { SessionsModule } from './sessions/sessions.module';
import { AnalysisModule } from './analysis/analysis.module';
import { User } from './users/entities/user.entity';
import { Child } from './children/entities/child.entity';
import { Session } from './sessions/entities/session.entity';
import { AnalysisResult } from './analysis/entities/analysis-result.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService): TypeOrmModuleOptions => {
        // 운영(NODE_ENV=production): synchronize 꺼짐 → 스키마는 마이그레이션으로 관리(부팅 시 자동 적용).
        // 개발/테스트: synchronize 켜짐 → 엔티티 기반 자동 동기화.
        const synchronize = config.get('NODE_ENV') !== 'production';
        return {
          type: 'mariadb',
          host: config.get('DB_HOST', 'localhost'),
          port: config.get<number>('DB_PORT', 3306),
          database: config.get('DB_NAME'),
          username: config.get('DB_USER'),
          password: config.get('DB_PASSWORD'),
          entities: [User, Child, Session, AnalysisResult],
          migrations: [__dirname + '/migrations/*.{ts,js}'],
          synchronize,
          migrationsRun: !synchronize,
          charset: 'utf8mb4',
        };
      },
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    ChildrenModule,
    SessionsModule,
    AnalysisModule,
  ],
  controllers: [HealthController],
  providers: [{ provide: APP_INTERCEPTOR, useClass: LoggingInterceptor }],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
