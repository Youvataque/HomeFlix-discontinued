import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/FondamentalAppCompo/SecondTop.dart';
import 'package:homeflix/Components/ViewComponents/Buttons/MainButton.dart';
import 'package:homeflix/Components/ViewComponents/InfoText.dart';
import 'package:homeflix/Data/KeyServices.dart';
import 'package:homeflix/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Settings extends StatefulWidget {
	final String? leftWord;
	const Settings({
		super.key,
		required this.leftWord
	});

	@override
	State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
	Map<String, TextEditingController> controlDatas = {
		"NIGHTCENTER_KEY": TextEditingController(),
		"NIGHTCENTER_IP": TextEditingController(),
		"NIGHTCENTER_PORT": TextEditingController(),
	};
	Future<String> getInfos() async {
		final temp = await PackageInfo.fromPlatform();
		return temp.version;
	}

	void saveAndRestart() {
		mainKey = GlobalKey<MainState>();
		Keyservices().save(controlDatas["NIGHTCENTER_IP"]!.text, controlDatas["NIGHTCENTER_KEY"]!.text, controlDatas["NIGHTCENTER_PORT"]!.text);
		Navigator.pushAndRemoveUntil(
			context,
			MaterialPageRoute(builder: (context) {
				return Main(key: mainKey);
			}),
			(_) => false,
		);
	}

	@override
	Widget build(BuildContext context) {
		controlDatas['NIGHTCENTER_KEY']!.text = Keyservices.nightcenterKey;
		controlDatas['NIGHTCENTER_IP']!.text = Keyservices.nightcenterIp;
		controlDatas['NIGHTCENTER_PORT']!.text = Keyservices.nightcenterPort;
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: Stack(
				children: [
					SingleChildScrollView(
						child:SizedBox(
							width: MediaQuery.sizeOf(context).width,
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 15), 
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										const Gap(105),
										const InfoText(text: "Voici vos différentes clefs API. Elles sont toutes nécéssaires au bon fonctionnement de l'application !"),
										const Gap(20),
										keysEditor(),
										const Gap(20),
										MainButton(
											func: () => saveAndRestart(),
											color: Theme.of(context).colorScheme.tertiary, 
											titleColor: Theme.of(context).scaffoldBackgroundColor,
											title: "Mettre à jour",
										),
										const Gap(5),
										printVersion()
									],
								)
							),
						),
					),
					Secondtop(
						title: "Paramètres",
						leftWord: widget.leftWord,
						color: Theme.of(context).primaryColor.withOpacity(0.5),
						icon: Icons.settings,
						func: () {},
					),
				],
			)
		);
	}

	FutureBuilder printVersion() {
		return FutureBuilder<String>(
			future: getInfos(),
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
				return Text(
					"Version ${snapshot.data}",
					style: TextStyle(
					color: Theme.of(context).colorScheme.tertiary,
					fontSize: 13,
					fontWeight: FontWeight.w300,
					),
				);
				} else {
				return const Text("wait...");
				}
			},
		);
	}

	Column keysEditor() {
		return Column(
			mainAxisAlignment: MainAxisAlignment.center,
			crossAxisAlignment: CrossAxisAlignment.center,
			children: controlDatas.entries.map((entry) {
				return SizedBox(
					width: double.infinity,
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						crossAxisAlignment: CrossAxisAlignment.center,
						children: [
							myTextField(entry.key, entry.value),
							const Gap(20)
						],
					),
				);
			}).toList(),
		);
	}

	SizedBox myTextField(String title, TextEditingController controller) {
		return SizedBox(
			height: 50,
			width: MediaQuery.sizeOf(context).width,
			child: TextField(
				controller: controller,
				decoration: InputDecoration(
					hintText: title,
					hintStyle: TextStyle(
						color: Theme.of(context).colorScheme.tertiary
					),
					contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
					filled: true,
					fillColor: Theme.of(context).primaryColor,
					focusColor: Theme.of(context).colorScheme.tertiary,
					focusedBorder: OutlineInputBorder(
						borderRadius: BorderRadius.circular(7.5),
						borderSide: BorderSide(
							width: 1,
							color: Theme.of(context).colorScheme.tertiary,
						)
					),
					enabledBorder: OutlineInputBorder(
						borderRadius: BorderRadius.circular(7.5),
						borderSide: BorderSide(
							width: 1,
							color: Theme.of(context).scaffoldBackgroundColor,
						)
					)
				),
				cursorColor: Theme.of(context).colorScheme.tertiary,
				textAlign: TextAlign.center,
				style: TextStyle(
					color: Theme.of(context).colorScheme.tertiary,
					fontWeight: FontWeight.w600
				),
			),
		);
	}
}