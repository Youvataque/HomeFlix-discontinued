import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/FondamentalAppCompo/SecondTop.dart';
import 'package:homeflix/Components/ViewComponents/SecondTitle.dart';
import 'package:homeflix/Data/TmdbServices.dart';
import 'package:homeflix/main.dart';

class Downloadpages extends StatefulWidget {
	final String secTitle;
	const Downloadpages({
		super.key,
		required this.secTitle,
	});

	@override
	State<Downloadpages> createState() => _DownloadpagesState();
}

class _DownloadpagesState extends State<Downloadpages> with TickerProviderStateMixin{

	///////////////////////////////////////////////////////////////
	/// UI des sous texts
	TextStyle sousText() {
		return TextStyle(
			fontSize: 14,
			fontWeight: FontWeight.w400,
			color: Theme.of(context).colorScheme.secondary
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: Stack(
				children: [
					SingleChildScrollView(
						child: Column(
							children: [
								const Gap(105),
								const Secondtitle(title: "État d'avancement"),
								const Gap(10),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 10),
									child: SizedBox(
										width: MediaQuery.sizeOf(context).width,
										child: ValueListenableBuilder<Map<String, dynamic>>(
											valueListenable: mainKey.currentState!.dataStatusNotifier,
											builder: (context, dataStatus, child) {
												return contentBody(dataStatus["queue"]);
											},
										)
									),
								),
								const Gap(40)
							],
						),
					),
					Secondtop(
						title: widget.secTitle,
						leftWord: "Serveur",
						color: Theme.of(context).primaryColor.withOpacity(0.5),
						icon: Icons.download,
						func: () {},
					),
				],
			)
		);
	}

	///////////////////////////////////////////////////////////////
	/// corp de la file d'attente
	Widget contentBody(Map<String, dynamic> datas) {
		return Column(
			children: datas.entries.map<Widget>((entry) {
				return Padding(
					padding: const EdgeInsets.only(bottom: 10),
					child: Row(
						children: [
							ClipRRect(
								borderRadius: BorderRadius.circular(7.5),
								child: SizedBox(
									height: 1.5 * 70,
									child: TMDBService().createImg(
										entry.key,
										70,
										entry.value['media'],
										2 / 3,
										false,
										"500"
									),
								)
							),
							const Gap(10),
							SizedBox(
								height: 1.5 * 70,
								width: MediaQuery.sizeOf(context).width - 105,
								child: Column(
								mainAxisAlignment: MainAxisAlignment.end,
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										entry.value['name'].replaceAll(RegExp(r'[._\-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),								
										maxLines: 2,
										style: sousText()
									),
									const Gap(10),
									SizedBox(
										height: 10,
										width: 200,
										child: LinearProgressIndicator(
											value: entry.value['percent'] / 100,
											borderRadius: BorderRadius.circular(3),
											color: Theme.of(context).colorScheme.tertiary,
										),
									),
									const Gap(2)
								],
							),
							)
						],
					),
				);
			}).toList()
		);
	}
}