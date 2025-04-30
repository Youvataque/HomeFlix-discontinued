import 'package:flutter/material.dart';

class PopUpTemplate extends StatelessWidget {
  final Widget child;
  final double heigth;
  final double width;
  final double padding;
  final double radius;
  final Alignment alignement;
  const PopUpTemplate({
    super.key,
    required this.child,
    required this.heigth,
	this.radius = 20,
	this.width = 350,
    this.padding = 60,
	this.alignement = Alignment.topCenter
  });

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: EdgeInsets.only(top: padding),
			child: Align(
				alignment: alignement,
				child: ClipRRect(
					borderRadius: BorderRadius.circular(radius),
					child: Container(
						height: heigth,
						width: width,
						decoration: BoxDecoration(
							color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
							borderRadius: BorderRadius.circular(radius)
						),
						child: Scaffold(
							resizeToAvoidBottomInset: false,
							body: GestureDetector(
								onTap: () => FocusScope.of(context).unfocus(),
								behavior: HitTestBehavior.opaque,
								child: child
							)
						)
					),
				),
			),
		);
	}
}