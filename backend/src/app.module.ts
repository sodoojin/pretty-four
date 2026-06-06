import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
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
      useFactory: (config: ConfigService) => ({
        type: 'mariadb',
        host: config.get('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 3306),
        database: config.get('DB_NAME'),
        username: config.get('DB_USER'),
        password: config.get('DB_PASSWORD'),
        entities: [User, Child, Session, AnalysisResult],
        synchronize: config.get('NODE_ENV') !== 'production',
        charset: 'utf8mb4',
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    ChildrenModule,
    SessionsModule,
    AnalysisModule,
  ],
})
export class AppModule {}
