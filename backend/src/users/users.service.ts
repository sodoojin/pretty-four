import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, AuthProvider } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  findById(id: string): Promise<User> {
    return this.repo.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User> {
    return this.repo.findOne({ where: { email }, select: ['id', 'email', 'password', 'provider', 'createdAt'] });
  }

  findBySocialId(provider: AuthProvider, providerId: string): Promise<User> {
    return this.repo.findOne({ where: { provider, providerId } });
  }

  create(data: Partial<User>): Promise<User> {
    return this.repo.save(this.repo.create(data));
  }
}
