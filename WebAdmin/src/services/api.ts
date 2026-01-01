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
    },

    async editContent(id: string, media: boolean, action: string, data: any): Promise<any> {
        const user = auth.currentUser;
        if (!user) throw new Error("User not authenticated");
        const token = await user.getIdToken();

        const response = await fetch(`${CONFIG.API_URL}/editContent`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id, media, action, data })
        });

        if (!response.ok) {
            const errData = await response.json().catch(() => ({}));
            throw new Error(errData.message || errData.error || `Failed to edit content: ${response.statusText}`);
        }
        return await response.json();
    },

    async deleteDownloading(id: string): Promise<void> {
        const user = auth.currentUser;
        if (!user) throw new Error("User not authenticated");
        const token = await user.getIdToken();

        const response = await fetch(`${CONFIG.API_URL}/deleteDownloading`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id })
        });

        if (!response.ok) {
            throw new Error(`Failed to delete downloading item: ${response.statusText}`);
        }
    }
};
