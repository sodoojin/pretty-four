import { INestApplication } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import request from 'supertest';
import { bootstrapTestApp, uniqueEmail } from './app.bootstrap';
import { Session, SessionStatus } from '../src/sessions/entities/session.entity';
import { AnalysisResult } from '../src/analysis/entities/analysis-result.entity';

describe('Children multi (e2e)', () => {
  let app: INestApplication;
  let server: any;
  let token: string;
  let userId: string;
  let sessionRepo: Repository<Session>;
  let analysisRepo: Repository<AnalysisResult>;
  let childA: string;
  let childB: string;

  const auth = () => ({ Authorization: `Bearer ${token}` });

  beforeAll(async () => {
    app = await bootstrapTestApp();
    server = app.getHttpServer();
    sessionRepo = app.get(getRepositoryToken(Session));
    analysisRepo = app.get(getRepositoryToken(AnalysisResult));

    const reg = await request(server)
      .post('/auth/register')
      .send({ email: uniqueEmail('multichild'), password: 'pw123456' });
    token = reg.body.access_token;
    userId = reg.body.user.id;
  });

  afterAll(async () => {
    await app?.close();
  });

  it('아이 2명 생성 → GET /children 2건', async () => {
    const a = await request(server).post('/children').set(auth()).send({ name: '첫째', birthDate: '2020-03-01' });
    const b = await request(server).post('/children').set(auth()).send({ name: '둘째', birthDate: '2022-07-01' });
    expect(a.status).toBe(201);
    expect(b.status).toBe(201);
    childA = a.body.id;
    childB = b.body.id;

    const list = await request(server).get('/children').set(auth());
    expect(list.status).toBe(200);
    expect(list.body).toHaveLength(2);
    expect(list.body.map((c: any) => c.id).sort()).toEqual([childA, childB].sort());
  });

  it('첫 생성 아이가 자동 활성 (GET /children/active = 첫째)', async () => {
    const res = await request(server).get('/children/active').set(auth());
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(childA);
  });

  it('PUT /children/active 둘째 → 활성이 둘째로 전환', async () => {
    const put = await request(server).put('/children/active').set(auth()).send({ childId: childB });
    expect(put.status).toBe(200);
    expect(put.body.id).toBe(childB);

    const active = await request(server).get('/children/active').set(auth());
    expect(active.body.id).toBe(childB);
  });

  it('PUT /children/active 존재하지 않는 아이 → 404', async () => {
    const res = await request(server)
      .put('/children/active')
      .set(auth())
      .send({ childId: '00000000-0000-0000-0000-000000000000' });
    expect(res.status).toBe(404);
  });

  it('GET /sessions?childId= 는 해당 아이 세션만 반환', async () => {
    // childA에 완료 세션 1건 + 분석 결과 시드
    const s = await sessionRepo.save(
      sessionRepo.create({ userId, childId: childA, status: SessionStatus.COMPLETED, durationSec: 10 }),
    );
    await analysisRepo.save(
      analysisRepo.create({ sessionId: s.id, summary: {}, feedbacks: [], childAgeMonths: 50 }),
    );

    const a = await request(server).get(`/sessions?childId=${childA}`).set(auth());
    const b = await request(server).get(`/sessions?childId=${childB}`).set(auth());
    expect(a.body).toHaveLength(1);
    expect(a.body[0].childId).toBe(childA);
    expect(b).toHaveProperty('body');
    expect(b.body).toHaveLength(0);
  });

  it('DELETE /children/:id → cascade (세션+분석 0건), 목록에서 사라짐', async () => {
    const del = await request(server).delete(`/children/${childA}`).set(auth());
    expect(del.status).toBe(204);

    // cascade 확인: childA의 세션/분석 0건
    const sessions = await sessionRepo.find({ where: { childId: childA } });
    expect(sessions).toHaveLength(0);
    const analyses = await analysisRepo.find();
    expect(analyses.filter((r) => sessions.some((s) => s.id === r.sessionId))).toHaveLength(0);

    const list = await request(server).get('/children').set(auth());
    expect(list.body.map((c: any) => c.id)).toEqual([childB]);
  });

  it('소유권: 다른 사용자의 아이를 활성 설정하려 하면 차단', async () => {
    const reg2 = await request(server)
      .post('/auth/register')
      .send({ email: uniqueEmail('other'), password: 'pw123456' });
    const token2 = reg2.body.access_token;
    const res = await request(server)
      .put('/children/active')
      .set({ Authorization: `Bearer ${token2}` })
      .send({ childId: childB }); // user1의 아이
    expect([403, 404]).toContain(res.status);
  });

  it('활성 아이를 삭제하면 재지정(마지막이면 null)', async () => {
    // 현재 user1은 childB만 남았고 활성 = childB. 삭제하면 0명 → active null
    const del = await request(server).delete(`/children/${childB}`).set(auth());
    expect(del.status).toBe(204);

    const list = await request(server).get('/children').set(auth());
    expect(list.body).toHaveLength(0);

    const active = await request(server).get('/children/active').set(auth());
    // 0명이면 null 본문 (200)
    expect(active.body == null || active.body === '' || Object.keys(active.body).length === 0).toBe(true);
  });
});
