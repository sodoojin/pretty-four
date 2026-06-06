import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { bootstrapTestApp, uniqueEmail } from './app.bootstrap';

describe('Auth (e2e)', () => {
  let app: INestApplication;
  const email = uniqueEmail('auth');
  const password = 'pw123456';

  beforeAll(async () => {
    app = await bootstrapTestApp();
  });

  afterAll(async () => {
    await app?.close();
  });

  it('POST /auth/register → 201 + access_token', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send({ email, password });
    expect(res.status).toBe(201);
    expect(res.body.access_token).toBeDefined();
    expect(res.body.user.email).toBe(email);
  });

  it('POST /auth/register 중복 이메일 → 409', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send({ email, password });
    expect(res.status).toBe(409);
  });

  it('POST /auth/login → 200 + access_token', async () => {
    const res = await request(app.getHttpServer()).post('/auth/login').send({ email, password });
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBeDefined();
  });

  it('POST /auth/login 잘못된 비밀번호 → 401', async () => {
    const res = await request(app.getHttpServer()).post('/auth/login').send({ email, password: 'wrong-password' });
    expect(res.status).toBe(401);
  });

  it('POST /auth/login 검증 실패(빈 body) → 400', async () => {
    const res = await request(app.getHttpServer()).post('/auth/login').send({});
    expect(res.status).toBe(400);
  });
});
