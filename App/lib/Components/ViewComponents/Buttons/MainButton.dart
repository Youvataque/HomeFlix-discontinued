import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///////////////////////////////////////////////////////////////
/// Bouton principale de l'application. 35px en hauteur et une longueur maximal en largeur.
class MainButton extends StatelessWidget {
	final VoidCallback func;
	final String? title;
	final bool type;
	final IconData? icon;
	final Color color;
	final Color titleColor;
	const MainButton({
		super.key,
		required this.func,
		this.title,
		this.type = false,
		this.icon,
		required this.color,
		required this.titleColor
	});
	
	@override
	Widget build(BuildContext context) {
		return SizedBox(
			height: 45,
			width: double.infinity,
			child: ElevatedButton(
				onPressed: () {
					HapticFeedback.mediumImpact();
					func();
				},
				style: buttonStyle(context),
				child: type? 
					Icon(
						icon!,
						size: 30,
						color: titleColor
					) 
				:
					Text(
						title!,
						style: TextStyle(
						fontWeight: FontWeight.w700,
						fontSize: 17,
						color: titleColor
						),
					),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// Style du bouton
	ButtonStyle buttonStyle(BuildContext context) {
		return ElevatedButton.styleFrom(
			backgroundColor: color,
			foregroundColor: titleColor,
			surfaceTintColor: Colors.transparent,
			padding: EdgeInsets.zero,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(7),
				side: BorderSide(
					width: 0.5,
					color: titleColor
				)
			)
		);
	}

}