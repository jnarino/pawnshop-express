import { AuthService } from '../../service/AuthService';
import { refreshTokenRequestSchema, RefreshTokenResponseDto } from '../../dto/auth/RefreshTokenDto';

export class RefreshTokenUseCase {
  constructor(private readonly authService: AuthService) {}

  async execute(input: unknown): Promise<RefreshTokenResponseDto> {
    const dto = refreshTokenRequestSchema.parse(input);
    return this.authService.refresh(dto.refresh_token);
  }
}
