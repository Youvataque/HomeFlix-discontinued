import { Request, Response, NextFunction } from 'express';
import admin from '../firebaseAdmin.js';

/////////////////////////////////////////////////////////////////////////////////
// Extension du type Request pour inclure user (Firebase DecodedIdToken)
declare module 'express-serve-static-core' {
	interface Request {
		user?: admin.auth.DecodedIdToken;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// Middleware d'authentification Firebase
const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
	const authHeader = req.headers.authorization;

	if (!authHeader || !authHeader.startsWith('Bearer ')) {
		return res.status(401).json({ message: 'Authorization header manquant ou mal formé' });
	}
	const token = authHeader.split(' ')[1];
	try {
		const decodedToken = await admin.auth().verifyIdToken(token, true);
		req.user = decodedToken;
		next();
	} catch (error: any) {
		if (error.code === 'auth/id-token-revoked') {
			return res.status(403).json({ message: 'Token révoqué. Veuillez vous reconnecter.' });
		}
		console.error('Erreur authMiddleware :', error);
		return res.status(403).json({ message: 'Token invalide ou expiré' });
	}
};

export default authMiddleware;