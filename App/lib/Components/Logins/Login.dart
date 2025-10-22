import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Logins/LogMainBod.dart';
import 'package:homeflix/Components/Logins/ResetPass.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';

import '../../main.dart';
import '../Tools/ErrorTools/LoginsError.dart';
import '../ViewComponents/Buttons/MainButton.dart';
import '../ViewComponents/Buttons/MyTextButton.dart';
import '../ViewComponents/Buttons/MyTextField.dart';

///////////////////////////////////////////////////////////////
/// Page de connexion
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

///////////////////////////////////////////////////////////////
/// Code principale
class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return LogMainBod(
      child: loginComponent(),
    );
  }

///////////////////////////////////////////////////////////////
/// textfields et boutons lié à la connexion
  Column loginComponent() {
    return Column(
      children: [
        MyTextField(
          controller: email,
          hintText: "Votre email",
          autofillHints: const [AutofillHints.email],

        ),
        const Gap(20),
        MyTextField(
          controller: password,
          hintText: "Votre mot de passe",
          hintType: true,
          autofillHints: const[AutofillHints.password],
        ),
        const Gap(5),
        toPassButton(),
        const Gap(30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: MainButton(
				func: () => login(),
				color: Theme.of(context).colorScheme.tertiary,
				titleColor: Theme.of(context).primaryColor,
				title: "Se connecter"
			),
        ),
        const Gap(50),
      ],
    );
  }

///////////////////////////////////////////////////////////////
/// bouton vers reset pass
  Widget toPassButton() {
    return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Align(
            alignment: Alignment.centerRight,
            child: MyTextButton(
                func: () => toPass(),
                title: "Un oublie ?"
            ),
          )
    );
  }

///////////////////////////////////////////////////////////////
/// logique vers signUp
  void toPass() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ResetPass()
        )
    );
  }

///////////////////////////////////////////////////////////////
/// logique de connexion
  void login() async {
    try {
		await FirebaseAuth.instance.signInWithEmailAndPassword(
			email: email.text.trim(),
			password: password.text.trim()
		);
		if (mounted) {
			Navigator.pushReplacement(
				context,
				MaterialPageRoute(builder: (context) => const Main())
			);
		}
		} catch (error) {
			if (mounted) {
				infoDialog(context, loginsError(error.toString()), true);
			}
		}
  }
}