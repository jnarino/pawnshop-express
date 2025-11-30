import express from 'express';
import cors from 'cors';
import { json } from 'express';
import { AuthController } from './controller/auth/AuthController';
import { AppUserController } from './controller/appUser/AppUserController';
import { createAuthRouter } from './route/auth/authRoute';
import { createAppUserRouter } from './route/appUser/appUserRoute';
import { errorMiddleware } from './middleware/errorMiddleware';
import { healthRouter } from './route/healthRoute';
import { createCustomerRouter } from './route/customer/customerRoute';
import { CustomerController } from './controller/customer/CustomerController';

export function createExpressApp(
  deps: {
    authController: AuthController;
    appUserController: AppUserController;
    jwtSecret: string;
    customerController: CustomerController;
  }
) {
  const app = express();

  app.use(cors());
  app.use(json());

  app.use('/health', healthRouter);
  app.use('/api/auth', createAuthRouter(deps.authController));
  app.use('/api/app-users', createAppUserRouter(deps.appUserController, deps.jwtSecret));
  app.use('/api/customer', createCustomerRouter(deps.customerController, deps.jwtSecret));


  app.use(errorMiddleware);

  return app;
}
