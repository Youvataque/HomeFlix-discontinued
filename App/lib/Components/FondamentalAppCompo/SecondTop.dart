import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

///////////////////////////////////////////////////////////////
/// Composant topOfView des sous pages avec bouton de retour
class Secondtop extends StatefulWidget implements PreferredSizeWidget {
	final String title;
	final String leftWord;
	final Color color;
	final IconData icon;
	final VoidCallback? func;
	final bool searchMode;
	final List<Widget> searchZone;
	final bool dataMode;
	final TextEditingController? query;
	const Secondtop({
		super.key,
		required this.title,
		required this.leftWord,
		required this.color,
		this.icon = Icons.refresh,
		this.func,
		this.searchZone = const [],
		this.searchMode = false,
		this.dataMode = false,
		this.query,
	});

	@override
	State<Secondtop> createState() => _SecondtopState();

	@override
  	Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SecondtopState extends State<Secondtop> {
	bool isSearch = false;

	@override
	Widget build(BuildContext context) {
		return ClipRect(
			child: BackdropFilter(
				filter: ImageFilter.blur(
					sigmaX: 10,
					sigmaY: 10
				),
				child: Container(
					width: MediaQuery.sizeOf(context).width,
					height: 95,
					color: widget.color,
					child: Center(
						child: Padding(
							padding: const EdgeInsets.only(top: 45),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: widget.searchMode ?
										widget.searchZone
									:
										[
											leftZone(),
											widget.dataMode ? const SizedBox.shrink() : titleWidget(),
											widget.dataMode ? rightZone2() : rightZone()
										],
							),
						)
					),
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone de de rtetour des details pages
	Widget leftZone() {
		return SizedBox(
			width: 100,
			child: Align(
				alignment: Alignment.centerLeft,
				child: Padding(
					padding: const EdgeInsets.only(left: 5),
					child: InkWell(
						onTap: () => Navigator.pop(context),
						splashColor: Colors.transparent,
						highlightColor: Colors.transparent,
						child: Row(
							children: [
								const Gap(5),
								Icon(
									Icons.navigate_before,
									size: 22,
									color: Theme.of(context).colorScheme.secondary,
								),
								SizedBox(
									width: 68,
									height: 40,
									child: Align(
										alignment: Alignment.centerLeft,
										child: Text(
											widget.leftWord,
											overflow: TextOverflow.ellipsis,
											style: TextStyle(
												color: Theme.of(context).colorScheme.secondary,
												fontSize: 14,
												fontWeight: FontWeight.w500
											),
										),
									)
								)
							],
						),
					)
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone de refresh des details pages
	SizedBox rightZone() {
		return SizedBox(
			width: 100,
			child: Align(
				alignment: Alignment.centerRight,
				child: Padding(
					padding: const EdgeInsets.only(right: 12),
					child: InkWell(
						onTap: widget.func!,
						splashColor: Colors.transparent,
						highlightColor: Colors.transparent,
						child: Icon(
							widget.icon,
							size: 22,
							color: Theme.of(context).colorScheme.secondary,
						),
					)
				),
			)
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone de recherche animé pour les datas
	Widget rightZone2() {
		return AnimatedCrossFade(
			firstChild: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					SizedBox(
						width: MediaQuery.sizeOf(context).width - 200,
						child: Text(
							widget.title,
							textAlign: TextAlign.center,
							style: TextStyle(
								color: Theme.of(context).colorScheme.secondary,
								fontSize: 17,
								fontWeight: FontWeight.w600
							),
						),
					),
					SizedBox(
						width: 100,
						child: Align(
							alignment: Alignment.centerRight,
							child: Padding(
								padding: const EdgeInsets.only(right: 12),
								child: InkWell(
									onTap: () {
										setState(() {
											HapticFeedback.lightImpact();
											isSearch = true;
										});
									},
									splashColor: Colors.transparent,
									highlightColor: Colors.transparent,
									child: Icon(
										widget.icon,
										size: 22,
										color: Theme.of(context).colorScheme.secondary,
									),
								)
							),
						)
					),
				],
			),
			secondChild: SizedBox(
				height: 35,
				width: MediaQuery.sizeOf(context).width - 100,
				child: Padding(
					padding: const EdgeInsets.only(right: 10),
					child: TextField(
						onSubmitted: (value) => setState(() {
							HapticFeedback.lightImpact();
							isSearch = false;
						}),
						controller: widget.query!,
						style: TextStyle(color: Theme.of(context).colorScheme.secondary),
						decoration: InputDecoration(
							contentPadding: const EdgeInsets.only(left: 10),
							hintText: 'Titre de l\'oeuvre',
							hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
							enabledBorder: OutlineInputBorder(
								borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
								borderRadius: BorderRadius.circular(7.5)
							),
							focusedBorder: OutlineInputBorder(
								borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
								borderRadius: BorderRadius.circular(7.5)
							),
						),
						cursorColor: Theme.of(context).colorScheme.secondary,
					),
				)
			),
			crossFadeState: isSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
			duration: const Duration(milliseconds: 200),
			firstCurve: Curves.easeIn,
			secondCurve: Curves.easeOut,
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone de titre des details pages (titre centré)
	Expanded titleWidget() {
		return Expanded(
			child: Text(
				widget.title,
				textAlign: TextAlign.center,
				style: TextStyle(
					color: Theme.of(context).colorScheme.secondary,
					fontSize: 17,
					fontWeight: FontWeight.w600
				),
			),
		);
	}
}