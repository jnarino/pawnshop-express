import { env } from './config/env';
import { pool, runMigrations } from './infrastructure/db';
import { PgAppUserRepository } from './infrastructure/persistence/PgAppUserRepository';
import { AppUserSessionRepository } from './infrastructure/persistence/AppUserSessionRepository';
import { AuthService } from './application/service/AuthService';
import { LoginUseCase } from './application/use-case/auth/LoginUseCase';
import { RefreshTokenUseCase } from './application/use-case/auth/RefreshTokenUseCase';
import { LogoutUseCase } from './application/use-case/auth/LogoutUseCase';
import { ListAppUserUseCase } from './application/use-case/appUser/ListAppUserUseCase';
import { CreateAppUserUseCase } from './application/use-case/appUser/CreateAppUserUseCase';
import { UpdateAppUserUseCase } from './application/use-case/appUser/UpdateAppUserUseCase';
import { DeleteAppUserUseCase } from './application/use-case/appUser/DeleteAppUserUseCase';
import { AuthController } from './interfaces/http/controller/AuthController';
import { AppUserController } from './interfaces/http/controller/AppUserController';
import { createExpressApp } from './interfaces/http';

export async function createApp() {
  await runMigrations();

  const appUserRepo = new PgAppUserRepository(pool);
  const sessionRepo = new AppUserSessionRepository(pool);

  const authService = new AuthService(appUserRepo, sessionRepo, env.jwtSecret);

  const loginUseCase = new LoginUseCase(authService);
  const refreshTokenUseCase = new RefreshTokenUseCase(authService);
  const logoutUseCase = new LogoutUseCase(authService);

  const listAppUserUseCase = new ListAppUserUseCase(appUserRepo);
  const createAppUserUseCase = new CreateAppUserUseCase(appUserRepo);
  const updateAppUserUseCase = new UpdateAppUserUseCase(appUserRepo);
  const deleteAppUserUseCase = new DeleteAppUserUseCase(appUserRepo);

  const authController = new AuthController(
    loginUseCase,
    refreshTokenUseCase,
    logoutUseCase
  );

  const appUserController = new AppUserController(
    listAppUserUseCase,
    createAppUserUseCase,
    updateAppUserUseCase,
    deleteAppUserUseCase
  );

  const app = createExpressApp({
    authController,
    appUserController,
    jwtSecret: env.jwtSecret
  });

  return app;
}
