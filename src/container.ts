import { pool, runMigrations } from './infrastructure/db';
import { env } from './config/env';
import { AuthService } from './application/service/AuthService';
import { CreateAppUserUseCase } from './application/use-case/appUser/command/CreateAppUserUseCase';
import { DeleteAppUserUseCase } from './application/use-case/appUser/command/DeleteAppUserUseCase';
import { UpdateAppUserUseCase } from './application/use-case/appUser/command/UpdateAppUserUseCase';
import { ListAppUserUseCase } from './application/use-case/appUser/query/ListAppUserUseCase';
import { LoginUseCase } from './application/use-case/auth/command/LoginUseCase';
import { LogoutUseCase } from './application/use-case/auth/command/LogoutUseCase';
import { RefreshTokenUseCase } from './application/use-case/auth/command/RefreshTokenUseCase';
import { CreateCustomerUseCase } from './application/use-case/customer/command/CreateCustomerUseCase';
import { DeleteCustomerUseCase } from './application/use-case/customer/command/DeleteCustomerUseCase';
import { UpdateCustomerUseCase } from './application/use-case/customer/command/UpdateCustomerUseCase';
import { FindCustomerUseCase } from './application/use-case/customer/query/FindCustomerUseCase';
import { GetCustomerByIdUseCase } from './application/use-case/customer/query/GetCustomerByIdUseCase';
import { PgAppUserRepository } from './infrastructure/persistence/appUser/PgAppUserRepository';
import { PgCustomerRepository } from './infrastructure/persistence/customer/PgCustomerRepository';
import { AppUserSessionRepository } from './infrastructure/persistence/session/AppUserSessionRepository';
import { createExpressApp } from './interfaces/http';
import { AppUserController } from './interfaces/http/controller/appUser/AppUserController';
import { AuthController } from './interfaces/http/controller/auth/AuthController';
import { CustomerController } from './interfaces/http/controller/customer/CustomerController';



export async function createApp() {
  await runMigrations();

  // Repositories
  const appUserRepo = new PgAppUserRepository(pool);
  const sessionRepo = new AppUserSessionRepository(pool);
  const customerRepo = new PgCustomerRepository(pool);

  // Services
  const authService = new AuthService(appUserRepo, sessionRepo, env.jwtSecret);

  // Auth use-cases
  const loginUseCase = new LoginUseCase(authService);
  const refreshTokenUseCase = new RefreshTokenUseCase(authService);
  const logoutUseCase = new LogoutUseCase(authService);

  // AppUser use-cases
  const listAppUserUseCase = new ListAppUserUseCase(appUserRepo);
  const createAppUserUseCase = new CreateAppUserUseCase(appUserRepo);
  const updateAppUserUseCase = new UpdateAppUserUseCase(appUserRepo);
  const deleteAppUserUseCase = new DeleteAppUserUseCase(appUserRepo);

  // Customer use-cases
  const createCustomerUseCase = new CreateCustomerUseCase(customerRepo);
  const updateCustomerUseCase = new UpdateCustomerUseCase(customerRepo);
  const deleteCustomerUseCase = new DeleteCustomerUseCase(customerRepo);
  const findCustomerUseCase = new FindCustomerUseCase(customerRepo);
  const getCustomerByIdUseCase = new GetCustomerByIdUseCase(customerRepo);

  // Controllers
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

  const customerController = new CustomerController(
    createCustomerUseCase,
    updateCustomerUseCase,
    deleteCustomerUseCase,
    findCustomerUseCase,
    getCustomerByIdUseCase
  );

  const app = createExpressApp({
    authController,
    appUserController,
    customerController,
    jwtSecret: env.jwtSecret
  });

  return app;
}
