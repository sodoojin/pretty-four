import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import axios from 'axios';
import FormData from 'form-data';
import Anthropic from '@anthropic-ai/sdk';
import { AnalysisResult } from './entities/analysis-result.entity';
import { SessionsService } from '../sessions/sessions.service';
import { SessionStatus } from '../sessions/entities/session.entity';

const AGE_CONTEXT: Record<string, string> = {
  infant: '만 2~3세 아이입니다. 단순하고 일관된 지시, 짧은 문장을 권장하세요. 감정 이름을 붙여주고 규칙을 반복적으로 알려주세요.',
  preschool: '만 4~6세 아이입니다. 선택지를 제공하고 규칙의 이유를 간단히 설명하세요. 칭찬과 긍정 강화를 활용하세요.',
  school: '만 7~10세 아이입니다. 논리적 설명을 하고 감정 공감을 먼저 하세요. 스스로 해결책을 찾도록 질문으로 유도하세요.',
  preteen: '만 11세 이상 아이입니다. 자율성을 존중하고 협상과 타협을 시도하세요. 의견을 존중받는다는 느낌을 주세요.',
};

function getAgeContext(ageMonths: number): string {
  if (ageMonths < 48) return AGE_CONTEXT.infant;
  if (ageMonths < 84) return AGE_CONTEXT.preschool;
  if (ageMonths < 132) return AGE_CONTEXT.school;
  return AGE_CONTEXT.preteen;
}

@Injectable()
export class AnalysisService {
  private readonly logger = new Logger(AnalysisService.name);
  private readonly anthropic: Anthropic;

  constructor(
    @InjectRepository(AnalysisResult)
    private readonly repo: Repository<AnalysisResult>,
    @Inject(forwardRef(() => SessionsService))
    private readonly sessions: SessionsService,
    private readonly config: ConfigService,
  ) {
    this.anthropic = new Anthropic({ apiKey: config.get('ANTHROPIC_API_KEY') });
  }

  async findBySessionId(sessionId: string): Promise<AnalysisResult | null> {
    return this.repo.findOne({ where: { sessionId } });
  }

  async runAnalysis(sessionId: string, audioPath: string, childAgeMonths: number): Promise<void> {
    try {
      const transcript = await this.transcribe(audioPath);
      const result = await this.analyze(transcript, childAgeMonths);

      await this.repo.save(this.repo.create({
        sessionId,
        summary: result.summary,
        feedbacks: result.feedbacks,
        rawTranscript: transcript,
        childAgeMonths,
      }));

      await this.sessions.updateStatus(sessionId, SessionStatus.COMPLETED);
    } catch (err) {
      this.logger.error(`Analysis failed for session ${sessionId}: ${err.message}`);
      await this.sessions.updateStatus(sessionId, SessionStatus.FAILED);
    } finally {
      try {
        fs.unlinkSync(audioPath);
      } catch {}
      await this.sessions.clearAudioPath(sessionId);
    }
  }

  private async transcribe(audioPath: string): Promise<string> {
    const form = new FormData();
    const ext = (audioPath.split('.').pop() || 'm4a').toLowerCase();
    form.append('file', fs.createReadStream(audioPath), { filename: `audio.${ext}` });
    form.append('model', 'whisper-1');
    form.append('response_format', 'verbose_json');
    form.append('timestamp_granularities[]', 'segment');

    const res = await axios.post('https://api.openai.com/v1/audio/transcriptions', form, {
      headers: {
        ...form.getHeaders(),
        Authorization: `Bearer ${this.config.get('OPENAI_API_KEY')}`,
      },
    });

    const segments: any[] = res.data.segments ?? [];
    return segments.map((s) => `[${Math.floor(s.start)}s] ${s.text}`).join('\n') || res.data.text;
  }

  private async analyze(transcript: string, ageMonths: number): Promise<{ summary: any; feedbacks: any[] }> {
    const ageContext = getAgeContext(ageMonths);

    const message = await this.anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 2048,
      messages: [
        {
          role: 'user',
          content: `당신은 발달심리학 기반의 육아 코칭 전문가입니다.

아이 정보: ${ageContext}

다음은 부모와 아이의 대화 전사본입니다 (타임스탬프 포함):
${transcript}

위 대화를 분석하여 다음 JSON 형식으로만 응답하세요. 코드 블록 없이 순수 JSON만 반환하세요:

{
  "summary": {
    "tone": "대화의 전반적인 톤 (예: 지시적, 공감적, 권위적 등)",
    "patterns": ["발견된 패턴 1", "발견된 패턴 2"],
    "improvements": ["개선 포인트 1", "개선 포인트 2"]
  },
  "feedbacks": [
    {
      "timestamp_sec": 타임스탬프(숫자),
      "original": "부모의 실제 발화",
      "suggestion": "더 효과적인 대안 발화",
      "reason": "이 대안이 더 효과적인 이유"
    }
  ]
}`,
        },
      ],
    });

    const raw = (message.content[0] as any).text.trim();
    const json = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');

    let parsed: any;
    try {
      parsed = JSON.parse(json);
    } catch {
      throw new Error('Claude 응답 JSON 파싱 실패');
    }

    if (!parsed.summary || !Array.isArray(parsed.feedbacks)) {
      throw new Error('Claude 응답 형식 오류');
    }

    return { summary: parsed.summary, feedbacks: parsed.feedbacks };
  }
}
