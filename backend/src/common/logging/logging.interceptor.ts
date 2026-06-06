import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

/**
 * 모든 HTTP 요청을 구조적 JSON 1줄로 기록한다.
 * 필드: correlationId, method, path(라우트 패턴), status, latencyMs (+ 에러 시 error/message).
 *
 * 보안: 요청 본문/쿼리/헤더/PII는 기록하지 않는다. path는 라우트 패턴(`/sessions/:id`)을 우선 사용해
 * 경로상의 식별자 노출을 줄인다.
 */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const http = context.switchToHttp();
    const req: any = http.getRequest();
    const res: any = http.getResponse();
    const start = Date.now();

    const correlationId = req.correlationId;
    const method = req.method;
    const path = req.route?.path ?? (req.originalUrl || req.url || '').split('?')[0];

    const emit = (extra: Record<string, unknown>): void => {
      this.logger.log(
        JSON.stringify({ correlationId, method, path, latencyMs: Date.now() - start, ...extra }),
      );
    };

    return next.handle().pipe(
      tap(() => emit({ status: res.statusCode })),
      catchError((err) => {
        emit({ status: err?.status ?? 500, error: err?.name, message: err?.message });
        return throwError(() => err);
      }),
    );
  }
}
