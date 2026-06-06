import { Test } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { SessionsService } from './sessions.service';
import { Session, SessionStatus } from './entities/session.entity';

describe('SessionsService (unit)', () => {
  let service: SessionsService;
  let repo: { findOne: jest.Mock; create: jest.Mock; save: jest.Mock; update: jest.Mock };

  beforeEach(async () => {
    repo = {
      findOne: jest.fn(),
      create: jest.fn((x) => x),
      save: jest.fn((x) => Promise.resolve({ id: 's1', ...x })),
      update: jest.fn(),
    };
    const moduleRef = await Test.createTestingModule({
      providers: [SessionsService, { provide: getRepositoryToken(Session), useValue: repo }],
    }).compile();
    service = moduleRef.get(SessionsService);
  });

  it('create는 PROCESSING 상태로 세션을 저장한다', async () => {
    const res = await service.create('u1', 'c1', 10, '/tmp/a.m4a');
    expect(repo.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', childId: 'c1', status: SessionStatus.PROCESSING }),
    );
    expect(res.id).toBe('s1');
  });

  it('findById 대상이 없으면 NotFoundException', async () => {
    repo.findOne.mockResolvedValue(null);
    await expect(service.findById('s1', 'u1')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('findById 소유자가 다르면 ForbiddenException', async () => {
    repo.findOne.mockResolvedValue({ id: 's1', userId: 'other' });
    await expect(service.findById('s1', 'u1')).rejects.toBeInstanceOf(ForbiddenException);
  });
});
