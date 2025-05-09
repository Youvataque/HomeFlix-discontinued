import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/Buttons/ButtonCheckBox.dart';
import 'package:homeflix/Components/ViewComponents/Buttons/MainButton.dart';
import 'package:homeflix/Components/ViewComponents/ErrorView.dart';
import 'package:homeflix/Components/ViewComponents/PopUpTemplate.dart';
import 'package:homeflix/Components/ViewComponents/SeasonPicker.dart';
import 'package:homeflix/main.dart';

///////////////////////////////////////////////////////////////
/// Page situé entre le bouton de téléchargement et l'action de dl.
/// elle sert à confirmer le téléchargement et préciser des informations pour les series.
class DownloadPopUp extends StatefulWidget {
	final bool movie;
	final void Function(Map<String, dynamic>) func;
	final String title;
	final String tmdbId;
	final int nbSaisons;
	final List<dynamic> seasons;
	const DownloadPopUp({
		super.key,
		required this.movie,
		required this.func,
		required this.title,
		required this.tmdbId,
		required this.nbSaisons,
		required this.seasons
	});

  @override
  State<DownloadPopUp> createState() => _DownloadPopUpState();
}

class _DownloadPopUpState extends State<DownloadPopUp> {
	String error = "";
	Map<String, dynamic> seasonEp = {};
	int isIn = 0;
	List<String> seasonList = [];
	List<String> episodeList = [];
	List<int> epFilter = [];
	SeasonPickStruct datas = SeasonPickStruct(
		seasonStart: 0,
		seasonEnd: 0,
		episode: 0,
		seasonEp: 0
	);

	@override
	void initState() {
		super.initState();
		for (int x = 1; x <= widget.nbSaisons; x++) {
			seasonList.add("Saison $x");
		}
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des sous composants

	///////////////////////////////////////////////////////////////
	/// titre du widget
	Align title(String title) {
		return Align(
			alignment: Alignment.centerLeft,
			child: Text(
				title,
				style: TextStyle(
					fontSize: 20,
					fontWeight: FontWeight.w700,
					color: Theme.of(context).colorScheme.secondary
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// style des texts généraux du widget
	TextStyle contentStyle(Color color) {
		return TextStyle(
			fontSize: 14,
			fontWeight: FontWeight.w400,
			color: color,
		);
	}

	///////////////////////////////////////////////////////////////
	/// text d'avertissement pour les films
	Align contentText(String title) {
		return Align(
			alignment: Alignment.centerLeft,
			child: Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					"Vous êtes sur le point de télécharger :",
					style: contentStyle(Theme.of(context).colorScheme.secondary),
				),
				Text(
					"${widget.title} !",
					style: contentStyle(Theme.of(context).colorScheme.tertiary),
					maxLines: 3,
					overflow: TextOverflow.ellipsis,
				),
				Text(
					"En êtes vous sur ?",
					style: contentStyle(Theme.of(context).colorScheme.secondary),
				),
			],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// Text de sélection des saisons de series
	Text seriesText(String text, Color? color)
	{
		return Text(
			text,
			maxLines: 3,
			overflow: TextOverflow.ellipsis,
			style: contentStyle(color?? Theme.of(context).colorScheme.secondary),
		);
	}

	@override
	Widget build(BuildContext context2) {
		return PopUpTemplate(
			padding: MediaQuery.sizeOf(context).height * 18 / 100,
			heigth: widget.movie ? 255 : 329,
			child: ValueListenableBuilder<Map<String, dynamic>>(
				valueListenable: mainKey.currentState!.dataStatusNotifier,
				builder: (context, dataStatus, child) {
					final serverContent = dataStatus['tv'];
					return Padding(
						padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
						child: widget.movie ? movieCheck(context2) : serieCheckTap(context2, serverContent)
					);
				},
			)
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des composants

	///////////////////////////////////////////////////////////////
	/// pop up pour les films
	Widget movieCheck(BuildContext context2) {
		return Column(
			children: [
				title("Attention !"),
				const Gap(10),
				contentText(widget.title),
				const Gap(30),
				MainButton(
					func: () {
						widget.func(seasonEp);
						Navigator.pop(context2);
					},
					color: Theme.of(context).primaryColor,
					titleColor: Theme.of(context).colorScheme.secondary,
					title: "Télécharger",
					icon: CupertinoIcons.arrow_down_doc,
				),
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// pop up pour les series 
	Widget serieCheckTap(BuildContext context2, Map<String, dynamic> serverContent) {
		List<int> alreadyIn = [];
		if (serverContent[widget.tmdbId] != null) {
			alreadyIn = (serverContent[widget.tmdbId]["seasons"] as Map<String, dynamic>)
				.entries
				.where((entry) => entry.value["complete"] == true)
				.map((entry) => int.parse(entry.key.substring(1)))
				.toList()
				..sort();
		}
		return Column(
			children: [
				title("Quelques précision !"),
				const Gap(10),
				Column(
					children: [
						Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								seriesText(widget.title, Theme.of(context).colorScheme.tertiary),
								const Gap(10),
								ButtonCheckBox(
									titles: const ["Saison", "Épisode"],
									isIn: isIn,
									onChanged: (value) => setState(() {isIn = value;})
								),
							],
						),
						const Gap(30),
						AnimatedCrossFade(
							firstChild: seriesSeaonPart(alreadyIn),
							secondChild: seriesEpisodePart(alreadyIn, serverContent),
							crossFadeState: isIn == 0 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
							duration: const Duration(milliseconds: 200)
						)
					],
				),
				const Gap(10),
				MainButton(
					func: () {
						if (widget.movie) {
							widget.func(seasonEp);
							Navigator.pop(context2);
						} else {
							if (selectfunction(serverContent)) {
								widget.func(seasonEp);
								Navigator.pop(context2);
							}
						}
					},
					color: Theme.of(context).colorScheme.tertiary,
					titleColor: Theme.of(context).primaryColor,
					title: "Télécharger",
					icon: CupertinoIcons.arrow_down_doc,
				),
				const Gap(5),
				ErrorView(
					key: UniqueKey(),
					error: error
				)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie 1 de la section séries (pour gérer les saisons compplètes)
	Wrap seriesSeaonPart(List<int> alreadyIn) {
		return Wrap(
			alignment: WrapAlignment.center,
			children: [
				SeasonPicker(strList: seasonList, pickerTitle: "Saison de départ", func: (p0) {setState(() {
					datas.seasonStart = p0;
				});}, disabledIndexes: alreadyIn,),
				Padding(
					padding: const EdgeInsets.only(top: 5),
					child: seriesText("  à  ", null),
				),
				SeasonPicker(strList: seasonList, pickerTitle: "Saison de fin", func: (p0) => datas.seasonEnd = p0, disabledIndexes: alreadyIn)
			],
		);
	}

	void updateSelectedSeas(int p0, Map<String, dynamic> serverContent) {
		datas.seasonEp = p0;
		if (serverContent[widget.tmdbId] != null) {
			epFilter = List<int>.from(
				serverContent[widget.tmdbId]["seasons"]["S$p0"]?["episode"] ?? []
			);
		}
		episodeList = [];
		for (int x = 1; x <= widget.seasons[p0 - 1]['episode_count']; x++) {
			episodeList.add("Épisode $x");
		}
		setState(() {});
	}

	///////////////////////////////////////////////////////////////
	/// partie 2 de la sections séries (pour gérer les épisodes d'une saison)
	Wrap seriesEpisodePart(List<int> alreadyIn, Map<String, dynamic> serverContent) {
	return Wrap(
		alignment: WrapAlignment.center,
		children: [
			SeasonPicker(
				strList: seasonList,
				pickerTitle: "Saison selectionné",
				func: (p0) => updateSelectedSeas(p0, serverContent),
				disabledIndexes: alreadyIn,
			),
			Padding(
				padding: const EdgeInsets.only(top: 5),
				child: seriesText("  à  ", null),
			),
			SeasonPicker(
				strList: episodeList,
				pickerTitle: "votre épisode",
				func: (p0) => datas.episode = p0,
				disabledIndexes: epFilter
			)
		],
	);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des fonctions

	//////////////////////////////////////////////////////////////
	/// fonction de sélection de la partie à éxécuter et des messages d'erreur
    bool selectfunction(Map<String, dynamic> serverContent) {
		if (isIn == 0) {
			if (datas.seasonStart == 0) {
				setState(() {
					error = "Erreur, il faut une première saison!";
				});
				return false;
			}
			if (datas.seasonEnd == 0) {
				setState(() {
					error = "Erreur, il faut une dernière saison !";
				});
				return false;
			}
			if (datas.seasonEnd < datas.seasonStart) {
				setState(() {
					error = "Erreur, dernière saison < à la première !";
				});
				return false;
			}
			addSeasonSpec(serverContent);
		} else {
			if (datas.seasonEp == 0) {
				setState(() {
					error = "Erreur, il faut choisir la saison de l'épisode !";
				});
				return false;
			}
			if (datas.episode == 0) {
				setState(() {
					error = "Erreur, il faut choisir un épisode !";
				});
				return false;
			}
			addEpisodeSpec(serverContent);
		}
		return true;
	}
	
    ///////////////////////////////////////////////////////////////
	/// ajoutes les seasons specs pour les saisons complètes
	void addSeasonSpec(Map<String, dynamic> serverContent) {
		seasonEp["seasons"] = {};
		for (int x = 1; x <= widget.nbSaisons; x++) {
			seasonEp["seasons"]["S$x"] = {
				"complete" : false,
				"episode" : [],
				"title" : widget.title,
			};
			if (x <= datas.seasonEnd && x >= datas.seasonStart) {
				seasonEp["seasons"]["S$x"] = {
					"complete" : true,
					"episode" : [-1],
					"size": widget.seasons[x - 1]['episode_count'],
					"title" : widget.title,
				};
			} else if (serverContent[widget.tmdbId] != null) {
				final temp = serverContent[widget.tmdbId]["seasons"] as Map<String, dynamic>;
				if (temp.containsKey("S$x")) {
					seasonEp["seasons"]["S$x"] = temp['S$x'];
				}
			}
		}
	}
	
	///////////////////////////////////////////////////////////////
	/// ajoutes les seasons specs pour les saisons épisode par épisode
	void addEpisodeSpec(Map<String, dynamic> serverContent) {
		final serverCheck = serverContent[widget.tmdbId] != null;
		Map<String, dynamic> tempData = {};
		if (serverCheck) tempData = serverContent[widget.tmdbId]["seasons"];
		List<int> toAdd = [];
		List<String> titles = [];
		if (serverCheck) {
			if (tempData.containsKey("S${datas.seasonEp}")) {
				toAdd = tempData["S${datas.seasonEp}"]["episode"].cast<int>();
				if (tempData["S${datas.seasonEp}"]["titles"] != null) {
					titles = tempData["S${datas.seasonEp}"]["titles"].cast<String>();
				} else {
					titles = [];
				}
			}
		}
		seasonEp["seasons"] = {};
		for (int x = 1; x <= widget.nbSaisons; x++) {
			seasonEp["seasons"]["S$x"] = {
				"complete" : false,
				"episode" : [],
				"titles": [],
				"title" : widget.title,
			};
			if (x == datas.seasonEp) {
				seasonEp["seasons"]["S$x"] = {
					"complete" : widget.seasons[x - 1]['episode_count'] == datas.episode,
					"episode" : [...toAdd, datas.episode],
					"titles" : [...titles, widget.title],
					"size": widget.seasons[x - 1]['episode_count'],
					"title" : widget.title,
				};
			} else if (serverCheck) {
				if (tempData.containsKey("S$x")) {
					seasonEp["seasons"]["S$x"] = tempData['S$x'];
				}
			}
		}
	}
}