import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import axios from 'axios';
import { OAuth2Client } from 'google-auth-library';
import { UsersService } from '../users/users.service';
import { AuthProvider } from '../users/entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {
    this.googleClient = new OAuth2Client(config.get('GOOGLE_CLIENT_ID'));
  }

  async register(dto: RegisterDto) {
    const existing = await this.users.findByEmail(dto.email);
    if (existing) throw new ConflictException('이미 사용 중인 이메일입니다.');

    const hashed = await bcrypt.hash(dto.password, 10);
    const user = await this.users.create({
      email: dto.email,
      password: hashed,
      provider: AuthProvider.EMAIL,
    });

    return { access_token: this.sign(user.id), user: { id: user.id, email: user.email } };
  }

  async login(dto: LoginDto) {
    const user = await this.users.findByEmail(dto.email);
    if (!user || !user.password) throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');

    const valid = await bcrypt.compare(dto.password, user.password);
    if (!valid) throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');

    return { access_token: this.sign(user.id), user: { id: user.id, email: user.email } };
  }

  async loginWithGoogle(idToken: string) {
    let payload: any;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.config.get('GOOGLE_CLIENT_ID'),
      });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('유효하지 않은 Google 토큰입니다.');
    }

    const { sub: googleId, email } = payload;
    let user = await this.users.findBySocialId(AuthProvider.GOOGLE, googleId);
    if (!user) {
      user = await this.users.create({
        email,
        provider: AuthProvider.GOOGLE,
        providerId: googleId,
      });
    }

    return { access_token: this.sign(user.id), user: { id: user.id, email: user.email } };
  }

  async loginWithKakao(kakaoAccessToken: string) {
    let kakaoUser: any;
    try {
      const res = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: { Authorization: `Bearer ${kakaoAccessToken}` },
      });
      kakaoUser = res.data;
    } catch {
      throw new UnauthorizedException('유효하지 않은 카카오 토큰입니다.');
    }

    const kakaoId = String(kakaoUser.id);
    const email = kakaoUser.kakao_account?.email;

    let user = await this.users.findBySocialId(AuthProvider.KAKAO, kakaoId);
    if (!user) {
      user = await this.users.create({
        email: email ?? null,
        provider: AuthProvider.KAKAO,
        providerId: kakaoId,
      });
    }

    return { access_token: this.sign(user.id), user: { id: user.id, email: user.email } };
  }

  private sign(userId: string): string {
    return this.jwt.sign({ sub: userId });
  }
}
