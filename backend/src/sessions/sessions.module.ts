import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Session } from './entities/session.entity';
import { SessionsService } from './sessions.service';
import { SessionsController } from './sessions.controller';
import { AnalysisModule } from '../analysis/analysis.module';
import { ChildrenModule } from '../children/children.module';

@Module({
  imports: [TypeOrmModule.forFeature([Session]), forwardRef(() => AnalysisModule), ChildrenModule],
  providers: [SessionsService],
  controllers: [SessionsController],
  exports: [SessionsService],
})
export class SessionsModule {}
