import { AuthService } from '../../service/AuthService';
import { loginRequestSchema, LoginResponseDto } from '../../dto/auth/LoginDto';

export class LoginUseCase {
  constructor(private readonly authService: AuthService) {}

  async execute(input: unknown): Promise<LoginResponseDto> {
    const dto = loginRequestSchema.parse(input);
    return this.authService.login(dto.username, dto.password);
  }
}
