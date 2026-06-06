import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'crypto';

export const CORRELATION_HEADER = 'x-correlation-id';

/**
 * 모든 요청에 correlation ID를 부여한다(들어온 헤더 우선, 없으면 생성).
 * 응답 헤더로도 돌려줘 클라이언트/프록시가 동일 ID로 추적할 수 있다.
 */
@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: any, res: any, next: () => void): void {
    const incoming = req.headers?.[CORRELATION_HEADER];
    const id = (Array.isArray(incoming) ? incoming[0] : incoming) || randomUUID();
    req.correlationId = id;
    res.setHeader?.(CORRELATION_HEADER, id);
    next();
  }
}
