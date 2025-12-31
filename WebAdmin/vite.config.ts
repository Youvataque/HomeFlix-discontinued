import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, process.cwd(), '');
    return {
        server: {
            proxy: {
                '/api': {
                    target: env.VITE_API_TARGET || 'http://localhost:4000',
                    changeOrigin: true,
                    secure: false,
                }
            }
        }
    }
});
