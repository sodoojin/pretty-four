import { IsString } from 'class-validator';

export class SetActiveChildDto {
  @IsString()
  childId: string;
}
