import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Tools/FormatTool/MultiSplit.dart';
import 'package:homeflix/Components/ViewComponents/ContentPages/DownloadPopUp.dart';
import 'package:homeflix/Data/NightServices.dart';
import 'package:homeflix/main.dart';

///////////////////////////////////////////////////////////////
/// composant gérant le téléchargement et l'affichage des torrents
class SourceGestionnary extends StatefulWidget {
	final String name;
	final String originalName;
	final Map<String, dynamic> selectData;
	final bool movie;
	final VoidCallback func;
	const SourceGestionnary({
		super.key,
		required this.name,
		required this.originalName,
		required this.selectData,
		required this.movie,
		required this.func
	});

	@override
	State<SourceGestionnary> createState() => _SourceGestionnaryState();
}

class _SourceGestionnaryState extends State<SourceGestionnary> {
	int currentPage = 1;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// sous composant du widget

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
	/// Text de la bar de gestion
	Text zoneTitle() {
		return Text(
			"Téléchargement",
				style: TextStyle(
				fontSize: 18,
				fontWeight: FontWeight.w700,
				color: Theme.of(context).colorScheme.secondary
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// button droite et gauche de la barre de téléchargement
	Widget barButton(VoidCallback func, IconData icon) {
		return SizedBox(
			width:50,
			height: 30,
			child: ElevatedButton(
				onPressed: () => func(),
				style: ElevatedButton.styleFrom(
					backgroundColor: Theme.of(context).primaryColor,
					foregroundColor: Theme.of(context).colorScheme.tertiary,
					padding: EdgeInsets.zero,
					surfaceTintColor: Colors.transparent,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(10),
						side: BorderSide(
							color: Theme.of(context).colorScheme.secondary,
							width: 0.5
						)
					)
				),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						if (icon == Icons.arrow_forward)
						Padding(
							padding: const EdgeInsets.only(right: 5),
							child: Text(
								(currentPage + 1).toString(),
								style: sousText(),
							),
						),
						Icon(
							icon,
							size: 15,
							color: Theme.of(context).colorScheme.secondary,
						),
						if (icon == Icons.arrow_back)
						Padding(
							padding: const EdgeInsets.only(left: 5),
							child: Text(
								(currentPage > 0 ? currentPage - 1 : 0).toString(),
								style: sousText(),
							),
						)
					],
				)
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// affiche le nombre de seeders et de leechers
	Row leechSeed(String value1, String value2) {
		return Row(
			children: [
				const Icon(
					Icons.arrow_upward_rounded,
					color: Colors.green,
					size: 20,
				),
				Text(
					value1,
					style: sousText(),
				),
				const Gap(10),
				const Icon(
					Icons.arrow_downward_rounded,
					color: Color.fromRGBO(229, 72, 77, 1),
					size: 20,
				),
				Text(
					value2,
					style: sousText(),
				)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// UI des boutons de téléchargement
	SizedBox linkButton(List<dynamic> results, int index) {
		List<dynamic> seasons = [];
		if (!widget.movie) {
			for (int x = 0; x < widget.selectData['seasons'].length; x++) {
				if (widget.selectData['seasons'][x]['season_number'] > 0) seasons.add(widget.selectData['seasons'][x]);
			}
		}
		return SizedBox(
			height: 80,
			width: MediaQuery.sizeOf(context).width,
			child: ElevatedButton(
				onPressed: () => showCupertinoModalPopup(
					context: context,
					filter: ImageFilter.blur(
						sigmaX: 10,
						sigmaY: 10
					),
					builder: (context) => DownloadPopUp(
						movie: widget.movie,
						func: (seasonEp) async => startDownload(
							results,
							index, 
							seasonEp,
						),
						title: results[index]['title'],
						tmdbId: widget.selectData['id'].toString(),
						nbSaisons: widget.movie ? -1 : seasons.length,
						seasons: widget.movie ? [] : seasons
					)
				),
				style: ElevatedButton.styleFrom(
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(7.5),
						side: BorderSide(
							color: Theme.of(context).colorScheme.secondary,
							width: 0.5
						)
					),
					padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
					backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
					foregroundColor: Theme.of(context).colorScheme.tertiary,
					surfaceTintColor: Colors.transparent,
					shadowColor: Colors.transparent
				),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							results[index]['title'],
							overflow: TextOverflow.ellipsis,
							maxLines: 2,
							style: sousText(),
						),
						const Gap(5),
						Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								leechSeed(
									results[index]['seed'].toString(),
									results[index]['leech'].toString()
								),
								Text(
									"${((results[index]['size'] / (1024 * 1024 * 1024)).toStringAsFixed(2))} Go",
									style: sousText(),
								)
							],
						)
					],
				),
			)
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// code principale

	@override
	Widget build(BuildContext context) {
		final splitResult = multiSplit(widget.name, " :,.");
		final nameForSearch = splitResult.isNotEmpty ? splitResult.join("%2B") : "default";
		return Column(
			children: [
				gestionnaryBar(),
				const Gap(20),
				gestionnaryContent(nameForSearch),
				const Gap(30)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// Bar de gestion des pages de torrent
	Row gestionnaryBar() {
		return Row(
			mainAxisAlignment: MainAxisAlignment.spaceBetween,
			children: [
				zoneTitle(),
				Row(
					children: [
						barButton(
							() => setState(() {
								if (currentPage > 1) currentPage -= 1;
							}), 
							Icons.arrow_back
						),
						const Gap(8),
						Text(
							currentPage.toString(),
							style: TextStyle(
								fontSize: 18,
								color: Theme.of(context).colorScheme.tertiary,
								fontWeight: FontWeight.w700
							),
						),
						const Gap(8),
						barButton(
							() => setState(() {
							  currentPage += 1;
							}),
							Icons.arrow_forward
						),
					],
				)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// Télécharge les liens 
	Widget gestionnaryContent(String nameForSearch) {
		return FutureBuilder(
			future: NIGHTServices().fetchQueryTorrent(currentPage, nameForSearch),
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.waiting) {
					return Center(
						child: CupertinoActivityIndicator(
							color: Theme.of(context).colorScheme.secondary,
							radius: 15,
						),
					);
				} else if (snapshot.hasError) {
					return Center(child: Text('Erreur: ${snapshot.error}'));
				} else {
					final results = snapshot.data as List<dynamic>;
					return Column(
						children: List.generate(
							results.length,
							(index) => Padding(
								padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
								child: linkButton(results, index)
							)
						),
					);
				}
			},
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// fonction du widget

	///////////////////////////////////////////////////////////////
	/// télécharge le contenu sélectionné dans le serveur
	void startDownload(List<dynamic> results, int index, Map<String, dynamic> seasonEpi) async {
		Map<String, dynamic> result = {};
		if (widget.movie) {
			result = {
				"id": widget.selectData['id'].toString(),
				'title': widget.name,
				'originalTitle': widget.originalName,
				'name': results[index]['title'],
				'media': widget.movie,
				'percent': 0.0
			};
		} else {
			result = {
				"id": widget.selectData['id'].toString(),
				'title': widget.name,
				'originalTitle': widget.originalName,
				'name': results[index]['title'],
				'media': widget.movie,
				'seasons': seasonEpi["seasons"],
				'percent': 0.0
			};
		}
		await NIGHTServices().sendDownloadRequest(results[index]['id'].toString(), results[index]['title']);
		await NIGHTServices().postDataStatus(result, "queue");
		mainKey.currentState!.dataStatusNotifier.value = await NIGHTServices().fetchDataStatus();
		widget.func();
	}
}