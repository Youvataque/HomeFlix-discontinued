import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Menueitem extends PopupMenuItem {
	final String title;
	final Color color;
	final IconData icon;
	final VoidCallback func;
	Menueitem({
		super.key,
		required this.title,
		required this.icon,
		required this.color,
		required this.func
	}) : super(
		child: Row(
			children: [
				Icon(
					icon,
					color: color,
					size: 22,
				),
				const Gap(10),
				Text(
					title,
					style: TextStyle(
						color: color,
						fontSize: 15,
						fontWeight: FontWeight.w500,
					),
				),
			],
		),
		onTap: () => func(),
	);
}