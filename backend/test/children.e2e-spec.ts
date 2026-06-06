import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { bootstrapTestApp, uniqueEmail } from './app.bootstrap';

describe('Children (e2e)', () => {
  let app: INestApplication;
  let token: string;

  beforeAll(async () => {
    app = await bootstrapTestApp();
    const email = uniqueEmail('child');
    const reg = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password: 'pw123456' });
    token = reg.body.access_token;
  });

  afterAll(async () => {
    await app?.close();
  });

  it('GET /children/current 토큰 없음 → 401', async () => {
    const res = await request(app.getHttpServer()).get('/children/current');
    expect(res.status).toBe(401);
  });

  it('POST /children → 201 + camelCase 응답', async () => {
    const res = await request(app.getHttpServer())
      .post('/children')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '아이', birthDate: '2021-05-01' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    // 모델 키 매핑(AGENTS.md §5): 엔티티 응답은 camelCase
    expect(res.body.birthDate).toBe('2021-05-01');
    expect(res.body).not.toHaveProperty('birth_date');
  });

  it('GET /children/current → 200 + 방금 만든 아이', async () => {
    const res = await request(app.getHttpServer())
      .get('/children/current')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('아이');
    expect(res.body.birthDate).toBe('2021-05-01');
  });
});
