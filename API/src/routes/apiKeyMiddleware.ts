import { Request, Response, NextFunction } from 'express';

const API_KEY = process.env.API_KEY;

/////////////////////////////////////////////////////////////////////////////////
// Middleware pour vérifier la clé API dans l'URL
export const apiKeyMiddleware = (req: Request, res: Response, next: NextFunction) => {
	const apiKey = req.query.api_key;
	if (apiKey !== API_KEY) {
		return res.status(403).json({ message: 'Clé API invalide' });
	}
	next();
};