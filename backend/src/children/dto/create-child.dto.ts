import { IsString, IsDateString } from 'class-validator';

export class CreateChildDto {
  @IsString()
  name: string;

  @IsDateString()
  birthDate: string;
}
