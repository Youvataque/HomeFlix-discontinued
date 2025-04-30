import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SeasonPickStruct {
	int seasonStart;
	int seasonEnd;
	int seasonEp;
	int episode;

	SeasonPickStruct({
		required this.seasonStart,
		required this.seasonEnd,
		required this.episode,
		required this.seasonEp,
	});
}

class SeasonPicker extends StatefulWidget {
	final List<String> strList;
	final String pickerTitle;
	final void Function(int) func;
	final List<int> disabledIndexes;

	const SeasonPicker({
		required this.strList,
		required this.pickerTitle,
		required this.func,
		required this.disabledIndexes,
		super.key,
	});

	@override
	State<SeasonPicker> createState() => _SeasonPickerState();
}

class _SeasonPickerState extends State<SeasonPicker> {
	int selectedIndex = 0;
	String title = "";
	bool picked = false;

	@override
	void initState() {
		super.initState();
		title = widget.pickerTitle;
	}

	@override
	Widget build(BuildContext context) {
		return pickerButton();
	}

	SizedBox pickerButton() {
		return SizedBox(
			height: 35,
			width: MediaQuery.sizeOf(context).width * 35 / 100,
			child: ElevatedButton(
				onPressed: () => showCupertinoDialog(
					context: context,
					builder: (context) => pickerUI(),
				),
				style: ElevatedButton.styleFrom(
					padding: EdgeInsets.zero,
					backgroundColor: picked ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(6),
						side: BorderSide(
							color: picked ?Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
							width: 0.5,
						),
					),
				),
				child: Text(
					title,
					overflow: TextOverflow.ellipsis,
					style: TextStyle(
						color: picked ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
						fontSize: 14,
					),
				),
			),
		);
	}

	Widget pickerUI() {
		return CupertinoAlertDialog(
			title: Text(widget.pickerTitle),
			content: SizedBox(
				height: 200,
				child: CupertinoPicker(
					itemExtent: 32.0,
					onSelectedItemChanged: (int index) {
						setState(() {
							selectedIndex = index;
						});
					},
					children: List.generate(widget.strList.length, (index) {
						final isDisabled = widget.disabledIndexes.contains(index + 1);
						return Center(
							child: Text(
								widget.strList[index],
								style: TextStyle(
									color: isDisabled ?
									Theme.of(context).disabledColor
											:
									Theme.of(context).primaryColor,
								),
							),
						);
					}),
				),
			),
			actions: [
				CupertinoDialogAction(
					isDefaultAction: true,
					child: Text(
						"Retour",
						style: TextStyle(
								color: Theme.of(context).primaryColor
						),
					),
					onPressed: () {
						Navigator.pop(context);
					},
				),
				CupertinoDialogAction(
					isDefaultAction: true,
					child: Text(
						"OK",
						style: TextStyle(
								color: Theme.of(context).colorScheme.tertiary
						),
					),
					onPressed: () {
						if (widget.disabledIndexes.contains(selectedIndex + 1)) {

						} else {
							setState(() {
								title = widget.strList[selectedIndex];
								picked = true;
								widget.func(selectedIndex + 1);
							});
							Navigator.pop(context);
						}
					},
				)
			],
		);
	}
}