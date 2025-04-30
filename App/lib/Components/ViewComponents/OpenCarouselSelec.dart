import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';

///////////////////////////////////////////////////////////////
/// composant générant le bouton de sélection d'un élément du carousel
class Opencarouselselec extends StatelessWidget {
  final VoidCallback func;
  const Opencarouselselec({
    super.key,
    required this.func
  });

  @override
  Widget build(BuildContext context) {
    return Align(
			alignment: Alignment.bottomCenter,
			child: Container(
				width: 250,
				height: 45,
				decoration: BoxDecoration(
					boxShadow: [
						myShadow(context)
					]
				),
				child: ElevatedButton(
					onPressed: () {
						HapticFeedback.lightImpact();
						func();
					},
					style: ElevatedButton.styleFrom(
						backgroundColor: Theme.of(context).colorScheme.tertiary,
						foregroundColor: Theme.of(context).primaryColor,
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(5),
						)
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								CupertinoIcons.videocam,
								color: Theme.of(context).primaryColor,
								size: 29,
							),
							const Gap(5),
							Text(
								"En savoir plus",
								style: TextStyle(
									fontSize: 17,
									color: Theme.of(context).scaffoldBackgroundColor,
									fontWeight: FontWeight.w600
								),
							),
						],
					)
				),
			)
		);
  }
}