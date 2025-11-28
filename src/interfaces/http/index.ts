import express from 'express';
import cors from 'cors';
import { json } from 'express';
import { AuthController } from './controller/AuthController';
import { AppUserController } from './controller/AppUserController';
import { createAuthRouter } from './route/authRoute';
import { createAppUserRouter } from './route/appUserRoute';
import { errorMiddleware } from './middleware/errorMiddleware';
import { healthRouter } from './route/healthRoute';

export function createExpressApp(
  deps: {
    authController: AuthController;
    appUserController: AppUserController;
    jwtSecret: string;
  }
) {
  const app = express();

  app.use(cors());
  app.use(json());

  app.use('/health', healthRouter);
  app.use('/api/auth', createAuthRouter(deps.authController));
  app.use('/api/app-users', createAppUserRouter(deps.appUserController, deps.jwtSecret));

  app.use(errorMiddleware);

  return app;
}
