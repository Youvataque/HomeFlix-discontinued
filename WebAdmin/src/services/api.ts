import { auth } from '../firebase';
import { CONFIG } from '../config';
import type { DataStructure } from '../types';

export const ApiService = {
    async fetchContentStatus(): Promise<DataStructure> {
        const user = auth.currentUser;
        if (!user) {
            throw new Error("User not authenticated");
        }
        const token = await user.getIdToken();

        try {
            const response = await fetch(`${CONFIG.API_URL}/contentStatus`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) {
                throw new Error(`API Error: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error("Failed to fetch content status:", error);
            throw error;
        }
    }
};
