import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalysisResult } from './entities/analysis-result.entity';
import { AnalysisService } from './analysis.service';
import { SessionsModule } from '../sessions/sessions.module';

@Module({
  imports: [TypeOrmModule.forFeature([AnalysisResult]), forwardRef(() => SessionsModule)],
  providers: [AnalysisService],
  exports: [AnalysisService],
})
export class AnalysisModule {}
