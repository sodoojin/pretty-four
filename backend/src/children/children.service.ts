import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Child } from './entities/child.entity';
import { CreateChildDto } from './dto/create-child.dto';

@Injectable()
export class ChildrenService {
  constructor(
    @InjectRepository(Child)
    private readonly repo: Repository<Child>,
  ) {}

  findCurrent(userId: string): Promise<Child | null> {
    return this.repo.findOne({ where: { userId }, order: { createdAt: 'ASC' } });
  }

  create(userId: string, dto: CreateChildDto): Promise<Child> {
    return this.repo.save(this.repo.create({ userId, name: dto.name, birthDate: dto.birthDate }));
  }

  async update(id: string, userId: string, dto: Partial<CreateChildDto>): Promise<Child> {
    const child = await this.repo.findOne({ where: { id } });
    if (!child) throw new NotFoundException();
    if (child.userId !== userId) throw new ForbiddenException();
    Object.assign(child, dto);
    return this.repo.save(child);
  }
}
