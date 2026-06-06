import { Test } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ChildrenService } from './children.service';
import { Child } from './entities/child.entity';
import { UsersService } from '../users/users.service';

describe('ChildrenService (unit)', () => {
  let service: ChildrenService;
  let repo: { findOne: jest.Mock; find: jest.Mock; create: jest.Mock; save: jest.Mock };
  let users: { findById: jest.Mock; updateActiveChild: jest.Mock };
  let manager: { find: jest.Mock; delete: jest.Mock };
  let dataSource: { transaction: jest.Mock };

  beforeEach(async () => {
    repo = {
      findOne: jest.fn(),
      find: jest.fn(),
      create: jest.fn((x) => x),
      save: jest.fn((x) => Promise.resolve({ id: 'c1', ...x })),
    };
    users = { findById: jest.fn(), updateActiveChild: jest.fn() };
    manager = { find: jest.fn(), delete: jest.fn() };
    dataSource = { transaction: jest.fn(async (cb: any) => cb(manager)) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        ChildrenService,
        { provide: getRepositoryToken(Child), useValue: repo },
        { provide: UsersService, useValue: users },
        { provide: DataSource, useValue: dataSource },
      ],
    }).compile();
    service = moduleRef.get(ChildrenService);
  });

  describe('findOneOwned', () => {
    it('없으면 NotFoundException', async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(service.findOneOwned('c1', 'u1')).rejects.toBeInstanceOf(NotFoundException);
    });
    it('소유자가 다르면 ForbiddenException', async () => {
      repo.findOne.mockResolvedValue({ id: 'c1', userId: 'other' });
      await expect(service.findOneOwned('c1', 'u1')).rejects.toBeInstanceOf(ForbiddenException);
    });
    it('소유자면 반환', async () => {
      repo.findOne.mockResolvedValue({ id: 'c1', userId: 'u1' });
      await expect(service.findOneOwned('c1', 'u1')).resolves.toEqual({ id: 'c1', userId: 'u1' });
    });
  });

  describe('create', () => {
    it('활성 아이가 없으면 새 아이를 활성으로 설정', async () => {
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: null });
      const res = await service.create('u1', { name: '아이', birthDate: '2021-01-01' });
      expect(res.id).toBe('c1');
      expect(users.updateActiveChild).toHaveBeenCalledWith('u1', 'c1');
    });
    it('이미 활성 아이가 있으면 변경하지 않음', async () => {
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: 'existing' });
      await service.create('u1', { name: '둘째', birthDate: '2023-01-01' });
      expect(users.updateActiveChild).not.toHaveBeenCalled();
    });
  });

  describe('getActive', () => {
    it('activeChildId가 유효하면 그 아이 반환', async () => {
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: 'cA' });
      repo.findOne.mockResolvedValue({ id: 'cA', userId: 'u1' });
      const res = await service.getActive('u1');
      expect(res).toEqual({ id: 'cA', userId: 'u1' });
      expect(users.updateActiveChild).not.toHaveBeenCalled();
    });
    it('active 미설정이면 첫 아이로 폴백 + self-heal 갱신', async () => {
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: null });
      repo.findOne.mockResolvedValue({ id: 'cFirst', userId: 'u1' }); // fallback 조회
      const res = await service.getActive('u1');
      expect(res?.id).toBe('cFirst');
      expect(users.updateActiveChild).toHaveBeenCalledWith('u1', 'cFirst');
    });
    it('아이가 0명이면 null', async () => {
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: null });
      repo.findOne.mockResolvedValue(null);
      await expect(service.getActive('u1')).resolves.toBeNull();
    });
  });

  describe('setActive', () => {
    it('소유 아이면 활성 갱신', async () => {
      repo.findOne.mockResolvedValue({ id: 'cB', userId: 'u1' });
      const res = await service.setActive('u1', 'cB');
      expect(users.updateActiveChild).toHaveBeenCalledWith('u1', 'cB');
      expect(res.id).toBe('cB');
    });
    it('타인 아이면 ForbiddenException', async () => {
      repo.findOne.mockResolvedValue({ id: 'cB', userId: 'other' });
      await expect(service.setActive('u1', 'cB')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('remove', () => {
    it('트랜잭션으로 analysis_results→sessions→child 삭제', async () => {
      repo.findOne
        .mockResolvedValueOnce({ id: 'cA', userId: 'u1' }) // findOneOwned
        .mockResolvedValueOnce({ id: 'cNext', userId: 'u1' }); // 재지정 next
      manager.find.mockResolvedValue([{ id: 's1' }, { id: 's2' }]);
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: 'cA' });

      await service.remove('cA', 'u1');

      expect(dataSource.transaction).toHaveBeenCalled();
      // analysis_results, sessions, child 3회 삭제
      expect(manager.delete).toHaveBeenCalledTimes(3);
      // 활성이던 cA 삭제 → 다음 아이로 재지정
      expect(users.updateActiveChild).toHaveBeenCalledWith('u1', 'cNext');
    });

    it('활성이 아니면 재지정하지 않음', async () => {
      repo.findOne.mockResolvedValueOnce({ id: 'cX', userId: 'u1' });
      manager.find.mockResolvedValue([]);
      users.findById.mockResolvedValue({ id: 'u1', activeChildId: 'other' });
      await service.remove('cX', 'u1');
      expect(users.updateActiveChild).not.toHaveBeenCalled();
    });

    it('타인 아이면 ForbiddenException (삭제 안 함)', async () => {
      repo.findOne.mockResolvedValue({ id: 'cA', userId: 'other' });
      await expect(service.remove('cA', 'u1')).rejects.toBeInstanceOf(ForbiddenException);
      expect(dataSource.transaction).not.toHaveBeenCalled();
    });
  });
});
