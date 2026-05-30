import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { Session } from '../../sessions/entities/session.entity';

@Entity('analysis_results')
export class AnalysisResult {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  sessionId: string;

  @OneToOne(() => Session)
  @JoinColumn({ name: 'sessionId' })
  session: Session;

  @Column({ type: 'json' })
  summary: object;

  @Column({ type: 'json' })
  feedbacks: object;

  @Column({ type: 'text', nullable: true })
  rawTranscript: string;

  @Column()
  childAgeMonths: number;

  @CreateDateColumn()
  createdAt: Date;
}
