String loginsError(String error) {
  switch (error) {
    case "[firebase_auth/invalid-email] The email address is badly formatted." :
      return "Le format de l'adresse email n'est pas valide.";
    case "[firebase_auth/invalid-credential] The supplied auth credential is malformed or has expired." :
      return "Aucun utilisateur trouvé avec cet email / mot de passe.";
    case "[firebase_auth/weak-password] Password should be at least 6 characters":
      return "Le mot de passe est trop court.";
    case "[firebase_auth/wrong-password] The password is invalid or the user does not have a password.":
      return "Le mot de passe est invalide.";
    case "[firebase_auth/too-many-requests] Access to this account has been temporarily disabled due to many failed login attempts. You can immediately restore it by resetting your password or you can try again later.":
      return "Le compte a été temporairement suspendu";
    default: 
      return "Nous avons rencontré une erreur.";
  }
}