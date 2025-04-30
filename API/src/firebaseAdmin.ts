   import admin from 'firebase-admin';
   import serviceAccount from '../firebasePass.json';

   admin.initializeApp({
     credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
   });

   export default admin;