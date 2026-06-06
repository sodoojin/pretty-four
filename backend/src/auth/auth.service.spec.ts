import { Test } from '@nestjs/testing';
import { UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';

describe('AuthService (unit)', () => {
  let service: AuthService;
  let users: { findByEmail: jest.Mock; create: jest.Mock; findBySocialId: jest.Mock };

  beforeEach(async () => {
    users = { findByEmail: jest.fn(), create: jest.fn(), findBySocialId: jest.fn() };
    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: users },
        { provide: JwtService, useValue: { sign: jest.fn().mockReturnValue('signed.jwt.token') } },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue(undefined) } },
      ],
    }).compile();
    service = moduleRef.get(AuthService);
  });

  describe('register', () => {
    it('중복 이메일이면 ConflictException (→ HTTP 409)', async () => {
      users.findByEmail.mockResolvedValue({ id: 'u1', email: 'a@b.com' });
      await expect(service.register({ email: 'a@b.com', password: 'pw123456' }))
        .rejects.toBeInstanceOf(ConflictException);
    });

    it('신규 이메일이면 access_token 반환 (→ HTTP 201)', async () => {
      users.findByEmail.mockResolvedValue(null);
      users.create.mockResolvedValue({ id: 'u1', email: 'a@b.com' });
      const res = await service.register({ email: 'a@b.com', password: 'pw123456' });
      expect(res.access_token).toBe('signed.jwt.token');
      expect(res.user).toEqual({ id: 'u1', email: 'a@b.com' });
    });
  });

  describe('login', () => {
    it('유저 없으면 UnauthorizedException (→ HTTP 401)', async () => {
      users.findByEmail.mockResolvedValue(null);
      await expect(service.login({ email: 'x@y.com', password: 'pw123456' }))
        .rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('비밀번호 불일치면 UnauthorizedException (→ HTTP 401)', async () => {
      const hash = await bcrypt.hash('correct', 10);
      users.findByEmail.mockResolvedValue({ id: 'u1', email: 'x@y.com', password: hash });
      await expect(service.login({ email: 'x@y.com', password: 'wrong' }))
        .rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('정상 로그인 시 access_token 반환 (→ HTTP 200)', async () => {
      const hash = await bcrypt.hash('correct', 10);
      users.findByEmail.mockResolvedValue({ id: 'u1', email: 'x@y.com', password: hash });
      const res = await service.login({ email: 'x@y.com', password: 'correct' });
      expect(res.access_token).toBe('signed.jwt.token');
      expect(res.user).toEqual({ id: 'u1', email: 'x@y.com' });
    });
  });
});
