import {
  Controller, Get, Post, Param, Query, UseGuards, Request,
  UseInterceptors, UploadedFile, Body, BadRequestException, NotFoundException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SessionsService } from './sessions.service';
import { AnalysisService } from '../analysis/analysis.service';
import { ChildrenService } from '../children/children.service';

@UseGuards(JwtAuthGuard)
@Controller('sessions')
export class SessionsController {
  constructor(
    private readonly sessions: SessionsService,
    private readonly analysis: AnalysisService,
    private readonly children: ChildrenService,
  ) {}

  @Get()
  list(@Request() req, @Query('limit') limit?: string) {
    return this.sessions.findRecent(req.user.id, limit ? parseInt(limit) : 20);
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('audio', {
    storage: diskStorage({
      destination: process.env.UPLOAD_DIR ?? '/app/uploads',
      filename: (_, file, cb) => {
        const ext = path.extname(file.originalname || '').toLowerCase() || '.m4a';
        cb(null, `${uuidv4()}${ext}`);
      },
    }),
    limits: { fileSize: 30 * 1024 * 1024 },
  }))
  async upload(
    @Request() req,
    @UploadedFile() file: Express.Multer.File,
    @Body('childId') childId: string,
    @Body('durationSec') durationSecStr: string,
  ) {
    if (!file) throw new BadRequestException('오디오 파일이 필요합니다.');
    if (!childId) throw new BadRequestException('childId가 필요합니다.');

    const durationSec = parseInt(durationSecStr) || 0;
    const session = await this.sessions.create(req.user.id, childId, durationSec, file.path);

    const child = await this.children.findCurrent(req.user.id);
    if (!child) throw new BadRequestException('아이 프로필이 없습니다.');

    const birthDate = new Date(child.birthDate);
    const now = new Date();
    const ageMonths = (now.getFullYear() - birthDate.getFullYear()) * 12 + (now.getMonth() - birthDate.getMonth());

    this.analysis.runAnalysis(session.id, file.path, ageMonths).catch(() => {});

    return { session_id: session.id };
  }

  @Get(':id')
  async getOne(@Request() req, @Param('id') id: string) {
    return this.sessions.findById(id, req.user.id);
  }

  @Get(':id/result')
  async getResult(@Request() req, @Param('id') id: string) {
    await this.sessions.findById(id, req.user.id);
    const result = await this.analysis.findBySessionId(id);
    if (!result) throw new NotFoundException('분석 결과가 아직 없습니다.');
    return result;
  }
}
