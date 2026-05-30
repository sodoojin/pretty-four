import { IsString } from 'class-validator';

export class KakaoLoginDto {
  @IsString()
  kakaoAccessToken: string;
}
