import { Controller, Post, Body, HttpCode } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { KakaoLoginDto } from './dto/kakao-login.dto';
import { GoogleTokenDto } from './dto/google-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  @HttpCode(200)
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('google/token')
  @HttpCode(200)
  googleToken(@Body() dto: GoogleTokenDto) {
    return this.auth.loginWithGoogle(dto.idToken);
  }

  @Post('kakao')
  @HttpCode(200)
  kakao(@Body() dto: KakaoLoginDto) {
    return this.auth.loginWithKakao(dto.kakaoAccessToken);
  }
}
