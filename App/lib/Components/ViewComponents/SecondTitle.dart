import 'package:flutter/material.dart';

///////////////////////////////////////////////////////////////
/// Composant générant les sous titre de section d'une page
class Secondtitle extends StatelessWidget {
	final String title;
	const Secondtitle({
		super.key,
		required this.title
	});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.only(left: 10),
			child: Align(
				alignment: Alignment.centerLeft,
				child: Text(
					title,
					style: TextStyle(
						color: Theme.of(context).colorScheme.secondary,
						fontWeight: FontWeight.w800,
						fontSize: 20
					),
				),
			),
		);
	}
}