import { IsString } from 'class-validator';

export class GoogleTokenDto {
  @IsString()
  idToken: string;
}
