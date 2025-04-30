import 'package:flutter/material.dart';

///////////////////////////////////////////////////////////////
/// composant générant une list centré des genres disponibles
class Categorigen extends StatefulWidget {
	final Function(int) func;
	final List<Map<String, dynamic>> data;
	const Categorigen({
		super.key,
		required this.func,
		required this.data,
	});

	@override
	State<Categorigen> createState() => _CategorigenState();
}

///////////////////////////////////////////////////////////////
/// corp du code
class _CategorigenState extends State<Categorigen> {
	@override
	Widget build(BuildContext context) {
		return Wrap(
			alignment: WrapAlignment.spaceBetween,
			spacing: 10,
			runSpacing: 10,
			children: List.generate(
				widget.data.length,
				(index) => SizedBox(
					height: 70,
					width: (MediaQuery.sizeOf(context).width - 45) / 3,
					child: myButton(index)
				)
			),
		);
  	}

	///////////////////////////////////////////////////////////////
	/// Ui du bouton
	Widget myButton(int index) {
		return ElevatedButton(
			onPressed: () => widget.func(index),
			style: ElevatedButton.styleFrom(
				padding:  EdgeInsets.zero,
				backgroundColor: Theme.of(context).primaryColor,
				foregroundColor: Theme.of(context).colorScheme.tertiary,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(10),
					side: BorderSide(
						width: 0.5,
						color: Theme.of(context).colorScheme.secondary
					)
				)
			),
			child: textOfButton(index)
		);
	}

	///////////////////////////////////////////////////////////////
	/// Ui du text du bouton
	Text textOfButton(int index) {
		return Text(
			widget.data[index]['name'],
			textAlign: TextAlign.center,
			style: TextStyle(
				color: Theme.of(context).colorScheme.secondary,
				fontSize: 16,
				fontWeight: FontWeight.w600
			),
		);
	}
}