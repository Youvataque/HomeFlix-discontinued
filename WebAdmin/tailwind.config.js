/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                background: '#14181D', // Color.fromRGBO(20, 24, 29, 1)
                surface: '#22282F', // primaryColor: Color.fromRGBO(34, 40, 47, 1)
                primary: '#10DFA8', // tertiary: Color.fromRGBO(16, 223, 168, 1)
                'text-main': '#EEEEEE', // secondary: Color.fromRGBO(238, 238, 238, 1)
                'text-muted': '#B4B4B4', // labelLarge: Color.fromRGBO(180, 180, 180, 1)
                'accent-blue': '#599DE6', // cursorColor: Color.fromARGB(255, 89, 157, 230)
                'divider': '#444343', // dividerColor: Color.fromARGB(255, 68, 67, 67)
            }
        },
    },
    plugins: [],
}
