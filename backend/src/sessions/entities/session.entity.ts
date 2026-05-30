import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Child } from '../../children/entities/child.entity';

export enum SessionStatus {
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

@Entity('sessions')
export class Session {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  childId: string;

  @ManyToOne(() => Child)
  @JoinColumn({ name: 'childId' })
  child: Child;

  @Column()
  userId: string;

  @Column({ nullable: true })
  audioPath: string;

  @Column({ default: 0 })
  durationSec: number;

  @Column({ type: 'enum', enum: SessionStatus, default: SessionStatus.PROCESSING })
  status: SessionStatus;

  @CreateDateColumn()
  recordedAt: Date;
}
