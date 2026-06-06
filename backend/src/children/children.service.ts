import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';
import { Child } from './entities/child.entity';
import { Session } from '../sessions/entities/session.entity';
import { AnalysisResult } from '../analysis/entities/analysis-result.entity';
import { UsersService } from '../users/users.service';
import { CreateChildDto } from './dto/create-child.dto';

@Injectable()
export class ChildrenService {
  constructor(
    @InjectRepository(Child)
    private readonly repo: Repository<Child>,
    private readonly users: UsersService,
    private readonly dataSource: DataSource,
  ) {}

  /** 사용자의 아이 목록(생성순). */
  findAll(userId: string): Promise<Child[]> {
    return this.repo.find({ where: { userId }, order: { createdAt: 'ASC' } });
  }

  /** 소유권 검증 후 단일 아이 반환. 업로드 나이 계산 등에서 사용. */
  async findOneOwned(id: string, userId: string): Promise<Child> {
    const child = await this.repo.findOne({ where: { id } });
    if (!child) throw new NotFoundException();
    if (child.userId !== userId) throw new ForbiddenException();
    return child;
  }

  /** 활성 아이. 미설정/유효하지 않으면 첫 아이로 폴백(그 값으로 self-heal). 없으면 null. */
  async getActive(userId: string): Promise<Child | null> {
    const user = await this.users.findById(userId);
    let child: Child | null = null;
    if (user?.activeChildId) {
      child = await this.repo.findOne({ where: { id: user.activeChildId, userId } });
    }
    if (!child) {
      child = await this.repo.findOne({ where: { userId }, order: { createdAt: 'ASC' } });
      if (child && user?.activeChildId !== child.id) {
        await this.users.updateActiveChild(userId, child.id);
      }
    }
    return child;
  }

  /** 활성 아이 설정(소유권 검증). */
  async setActive(userId: string, childId: string): Promise<Child> {
    const child = await this.findOneOwned(childId, userId);
    await this.users.updateActiveChild(userId, child.id);
    return child;
  }

  async create(userId: string, dto: CreateChildDto): Promise<Child> {
    const child = await this.repo.save(
      this.repo.create({ userId, name: dto.name, birthDate: dto.birthDate }),
    );
    const user = await this.users.findById(userId);
    if (!user?.activeChildId) {
      await this.users.updateActiveChild(userId, child.id);
    }
    return child;
  }

  async update(id: string, userId: string, dto: Partial<CreateChildDto>): Promise<Child> {
    const child = await this.findOneOwned(id, userId);
    Object.assign(child, dto);
    return this.repo.save(child);
  }

  /** 아이 삭제: 그 아이의 analysis_results → sessions → child 트랜잭션 cascade. 활성이면 재지정. */
  async remove(id: string, userId: string): Promise<void> {
    await this.findOneOwned(id, userId); // 소유권 검증

    await this.dataSource.transaction(async (m) => {
      const sessions = await m.find(Session, { where: { childId: id } });
      const sessionIds = sessions.map((s) => s.id);
      if (sessionIds.length) {
        await m.delete(AnalysisResult, { sessionId: In(sessionIds) });
      }
      await m.delete(Session, { childId: id });
      await m.delete(Child, { id });
    });

    const user = await this.users.findById(userId);
    if (user?.activeChildId === id) {
      const next = await this.repo.findOne({ where: { userId }, order: { createdAt: 'ASC' } });
      await this.users.updateActiveChild(userId, next?.id ?? null);
    }
  }
}
