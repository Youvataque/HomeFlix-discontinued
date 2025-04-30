import 'package:flutter/material.dart';

class ButtonCheckBox extends StatefulWidget {
	final List<String> titles;
	final int isIn;
	final ValueChanged<int> onChanged;
	const ButtonCheckBox({
		super.key,
		required this.titles,
		required this.isIn,
		required this.onChanged
	});

	@override
	State<ButtonCheckBox> createState() => _ButtonCheckBoxState();
}

class _ButtonCheckBoxState extends State<ButtonCheckBox> with SingleTickerProviderStateMixin {
  	late AnimationController _animationController;

	@override
	void initState() {
		super.initState();
		_animationController = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
	}

	@override
	void dispose() {
		_animationController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Wrap(
			spacing: 10,
			runSpacing: 10,
			children: List.generate(
				widget.titles.length,
				(index) => _buildButton(context, index),
			),
		);
	}

	Widget _buildButton(BuildContext context, int index) {
		bool isSelected = widget.isIn == index;
		return GestureDetector(
			onTap: () {
				widget.onChanged(index);
				_animationController.forward(from: 0);
			},
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				curve: Curves.easeInOut,
				padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
				decoration: BoxDecoration(
					color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
					borderRadius: BorderRadius.circular(7),
					border: Border.all(
						color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
						width: isSelected ? 1 : 0.5,
					),
					boxShadow: isSelected
						? [
							BoxShadow(
								color: Theme.of(context).primaryColor.withOpacity(0.3),
								blurRadius: 5,
								spreadRadius: 2,
							),
						]
						: [],
				),
			child: _buildButtonText(context, index, isSelected),
			),
		);
	}

	Widget _buildButtonText(BuildContext context, int index, bool isSelected) {
		return Text(
			widget.titles[index],
			style: TextStyle(
				fontSize: 14,
				fontWeight: FontWeight.w600,
				color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
			),
		);
	}
}