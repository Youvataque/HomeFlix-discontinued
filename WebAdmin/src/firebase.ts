// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyA0BMBCZGa0o91Nlf8575KufUSFpAI44G8",
    authDomain: "homeflix-438f9.firebaseapp.com",
    projectId: "homeflix-438f9",
    storageBucket: "homeflix-438f9.firebasestorage.app",
    messagingSenderId: "207859538194",
    appId: "1:207859538194:web:c25bda9da5f09a6558fbcb"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
