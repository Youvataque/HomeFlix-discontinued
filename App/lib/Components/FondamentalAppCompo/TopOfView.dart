import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';

class TopOfView extends StatefulWidget {
	final VoidCallback goSettings;
	final VoidCallback search;
	const TopOfView({
		super.key,
		required this.goSettings,
		required this.search
	});

	@override
	State<TopOfView> createState() => _TopOfViewState();
}

class _TopOfViewState extends State<TopOfView> {

	///////////////////////////////////////////////////////////////
	/// corp du code
	@override
	Widget build(BuildContext context) {
		return SizedBox(
			height: 110,
			width: MediaQuery.sizeOf(context).width,
			child: Stack(
				children: [
					Container(
						height: 100,
						decoration: BoxDecoration(
							gradient: LinearGradient(
								begin: Alignment.topCenter,
								end: Alignment.bottomCenter,
								colors: [
									Theme.of(context).scaffoldBackgroundColor.withOpacity(1),
									Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
								],
							),
						),
					),
					Padding(
						padding: const EdgeInsets.only(top: 60),
						child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Padding(
								padding: const EdgeInsets.only(left: 7),
								child: Container(
									height: 50,
									width: 50,
									decoration: BoxDecoration(
										borderRadius: BorderRadius.circular(100),
										boxShadow: [myShadow(context)]
									),
									child: Image.asset(
										"src/images/logo.png",
										fit: BoxFit.cover,
									),
								),
							),
							leftButtons()
						],
					),
					)
				],
			)
		); 
	}

	///////////////////////////////////////////////////////////////
	/// ui des boutons
	SizedBox button(IconData icon, VoidCallback func) {
		return SizedBox(
			height: 50,
			width: 50,
			child: ClipRRect(
				borderRadius: BorderRadius.circular(15),
				child: BackdropFilter(
					filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
					child: ElevatedButton(
						onPressed: () {
							HapticFeedback.lightImpact();
							func();
						},
						style: ElevatedButton.styleFrom(
							padding: EdgeInsets.zero,
							backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
							foregroundColor: Theme.of(context).primaryColor,
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(15)
							)
						),
						child: Icon(
							icon,
							size: 20,
							color: Theme.of(context).colorScheme.secondary,
						)
					),
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// création du bouton search et refresh
	Padding leftButtons() {
		return Padding(
			padding: const EdgeInsets.only(right: 10),
			child: Row(
				children: [
					button(
						CupertinoIcons.search,
						() => widget.search()
					),
					const Gap(10),
					button(
						CupertinoIcons.settings_solid,
						() => widget.goSettings()
					),
				],
			),
		);
	}
}