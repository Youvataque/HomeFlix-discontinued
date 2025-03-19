import { Request, Response, NextFunction } from 'express';
import admin from '../firebaseAdmin.js';

const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  const authorizationHeader = req.headers.authorization;
  const token = authorizationHeader?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token manquant' });
  }

  try {
    await admin.auth().verifyIdToken(token, true);
    next();
  } catch (error: any) {
    if (error.code === 'auth/id-token-revoked') {
      return res.status(403).json({ message: 'Token révoqué. Veuillez vous reconnecter.' });
    }
    return res.status(403).json({ message: 'Token invalide' });
  }
};

export default authMiddleware;
