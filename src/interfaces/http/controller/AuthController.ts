// src/interfaces/http/controller/AuthController.ts
import { Request, Response, NextFunction } from 'express';
import { LoginUseCase } from '../../../application/use-case/auth/LoginUseCase';
import { RefreshTokenUseCase } from '../../../application/use-case/auth/RefreshTokenUseCase';
import { LogoutUseCase } from '../../../application/use-case/auth/LogoutUseCase';

export class AuthController {
  constructor(
    private readonly loginUseCase: LoginUseCase,
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
    private readonly logoutUseCase: LogoutUseCase
  ) { }

  login = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.loginUseCase.execute(req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  };

  refresh = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.refreshTokenUseCase.execute(req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  };

  logout = async (req: Request, res: Response, next: NextFunction) => {
    try {
      await this.logoutUseCase.execute(req.body);
      return res.status(204).send();
    } catch (err) {
      return next(err);
    }
  };
}
