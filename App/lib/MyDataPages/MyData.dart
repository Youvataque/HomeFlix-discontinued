import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/SpecWidget.dart';
import 'package:homeflix/MyDataPages/DataView.dart';
import 'package:homeflix/Components/ViewComponents/SecondTitle.dart';
import 'package:homeflix/MyDataPages/DownloadPages.dart';
import 'package:homeflix/main.dart';

class MyData extends StatefulWidget {
	const MyData({super.key});

	@override
	State<MyData> createState() => _MyDataState();
}

class _MyDataState extends State<MyData> {

	///////////////////////////////////////////////////////////////
	/// UI des sous texts
	TextStyle sousText() {
		return TextStyle(
			fontSize: 14,
			fontWeight: FontWeight.w400,
			color: Theme.of(context).colorScheme.secondary
		);
	}

	///////////////////////////////////////////////////////////////
	/// ui du titre de l'oeuvre
	TextStyle titleText() {
		return TextStyle(
			fontSize: 17,
			fontWeight: FontWeight.w700,
			color: Theme.of(context).colorScheme.secondary
		);
	}

	///////////////////////////////////////////////////////////////
	/// boutons principaux
	SizedBox sectionButton(String sectionName, double width, String img, VoidCallback func) {
		return SizedBox(
			width: width,
			height: 100,
			child: ClipRRect(
				borderRadius: BorderRadius.circular(7.5),
				child: Stack(
					children: [
						SizedBox(
							width: width,
							height: 100,
							child: Image.asset(
								img,
								fit: BoxFit.cover,
							),
						),
						SizedBox(
							width: width,
							height: 100,
							child: BackdropFilter(
								filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
								child: ElevatedButton(
									onPressed: () {
										HapticFeedback.lightImpact();
										func();
									},
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
										foregroundColor: Theme.of(context).colorScheme.tertiary,
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(7.5),
											side: BorderSide(
												width: 0.5,
												color: Theme.of(context).colorScheme.secondary,
											),
										),
										surfaceTintColor: Colors.transparent,
									),
									child: Text(
										sectionName,
										style: titleText(),
									),
								),
							),
						),
					],
				)
			)
		);
	}

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
				child: Column(
			children: [
				const Gap(125),
				const Secondtitle(title: "Gestion contenue"),
				const Gap(10),
				Row(
					children: [
						const Gap(10),
						sectionButton(
							"Films",
							MediaQuery.sizeOf(context).width / 2 - 15,
							"src/images/avengers.jpg",
							() => Navigator.push(
								context,
								MaterialPageRoute(builder: (context) => const Dataview(
									secTitle: "Films",
									where: "movie",
								))
							),
						),
						const Gap(10),
						sectionButton(
							"Séries",
							MediaQuery.sizeOf(context).width / 2 - 15,
							"src/images/suits.jpeg",
							() => Navigator.push(
								context,
								MaterialPageRoute(builder: (context) => const Dataview(
									secTitle: "Séries",
									where: "tv",
								))
							),
						),
						const Gap(10),
					],
				),
				const Gap(10),
				sectionButton(
					"En téléchargement",
					MediaQuery.sizeOf(context).width - 20,
					"src/images/downloadImg.png",
					() => Navigator.push(
						context,
						MaterialPageRoute(builder: (context) => Downloadpages(
							key: ValueKey(mainKey.currentState!.dataStatusNotifier),
							secTitle: "Téléchargement",
						))
					),
				),
				const Gap(35),
				const Secondtitle(title: "Information serveur"),
				const Gap(10),
				const SpecWidget(),
				const Gap(20)
			],
				)
		);
	}
}