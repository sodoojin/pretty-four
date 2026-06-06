import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Session, SessionStatus } from './entities/session.entity';

@Injectable()
export class SessionsService {
  constructor(
    @InjectRepository(Session)
    private readonly repo: Repository<Session>,
  ) {}

  create(userId: string, childId: string, durationSec: number, audioPath: string): Promise<Session> {
    return this.repo.save(this.repo.create({ userId, childId, durationSec, audioPath, status: SessionStatus.PROCESSING }));
  }

  async findById(id: string, userId: string): Promise<Session> {
    const session = await this.repo.findOne({ where: { id } });
    if (!session) throw new NotFoundException();
    if (session.userId !== userId) throw new ForbiddenException();
    return session;
  }

  findRecent(userId: string, limit = 20, childId?: string): Promise<Session[]> {
    const where: { userId: string; status: SessionStatus; childId?: string } = {
      userId,
      status: SessionStatus.COMPLETED,
    };
    if (childId) where.childId = childId;
    return this.repo.find({ where, order: { recordedAt: 'DESC' }, take: limit });
  }

  async updateStatus(id: string, status: SessionStatus): Promise<void> {
    await this.repo.update(id, { status });
  }

  async clearAudioPath(id: string): Promise<void> {
    await this.repo.update(id, { audioPath: null });
  }
}
