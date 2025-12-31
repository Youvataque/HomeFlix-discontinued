import { auth } from './firebase';
import {
    signInWithEmailAndPassword,
    signOut,
    onAuthStateChanged,
    type User
} from 'firebase/auth';

class AuthService {
    currentUser: User | null = null;
    loading: boolean = true;
    private stateListeners: ((user: User | null) => void)[] = [];

    constructor() {
        onAuthStateChanged(auth, (user) => {
            this.currentUser = user;
            this.loading = false;
            this.notifyListeners();
        });
    }

    async login(email: string, password: string) {
        try {
            await signInWithEmailAndPassword(auth, email, password);
        } catch (error) {
            console.error("Login failed:", error);
            throw error;
        }
    }

    async logout() {
        try {
            await signOut(auth);
        } catch (error) {
            console.error("Logout failed:", error);
            throw error;
        }
    }

    addListener(listener: (user: User | null) => void) {
        this.stateListeners.push(listener);
        // Immediately notify with current state if not loading
        if (!this.loading) {
            listener(this.currentUser);
        }
    }

    private notifyListeners() {
        this.stateListeners.forEach(listener => listener(this.currentUser));
    }
}

export const authService = new AuthService();
