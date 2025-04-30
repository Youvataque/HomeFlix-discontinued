import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/FondamentalAppCompo/SecondTop.dart';
import 'package:homeflix/Components/Tools/FormatTool/MinToHour.dart';
import 'package:homeflix/Components/Tools/FormatTool/NumberWithCom.dart';
import 'package:homeflix/Components/ViewComponents/ContentPages/SourceGestionnary.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Components/ViewComponents/PopUpTemplate.dart';
import 'package:homeflix/main.dart';
import 'package:readmore/readmore.dart';

///////////////////////////////////////////////////////////////
/// Affiche le contenu d'un film ou d'une série et permet son téléchargement
class Contentview extends StatefulWidget {
	final Map<String, dynamic> datas;
	final bool movie;
	final Widget img;
	final String leftWord;
	const Contentview({
		super.key,
		required this.datas,
		required this.img,
		required this.movie,
		required this.leftWord
	});

	@override
	State<Contentview> createState() => _ContentviewState();
}

class _ContentviewState extends State<Contentview> {
	TextEditingController controller = TextEditingController();
	String searchName = "";
	String originalName = "";
	@override
	void initState() {
		super.initState();
		final temp = widget.datas['origin_country'] as List<dynamic>;
		searchName = temp.contains("US") || temp.contains("CA") ? 
			widget.datas[widget.movie ? 'original_title' : 'original_name']
		:
			widget.datas[widget.movie ? 'title' : 'name'];
		originalName = temp.contains("US") || temp.contains("CA") ? 
			widget.datas[widget.movie ? 'title' : 'name']
		:
			widget.datas[widget.movie ? 'original_title' : 'original_name'];
		controller.text = searchName;
	}

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
	Text titleText() {
		return Text(
			widget.datas[widget.movie ? 'title' : 'name'],
			style: TextStyle(
				fontSize: 17,
				fontWeight: FontWeight.w700,
				color: Theme.of(context).colorScheme.secondary
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// UI du composant affiché si le film est déjà téléchargé
	Padding alreadyInDB(String message) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: Container(
				width: MediaQuery.sizeOf(context).width,
				height: 40,
				decoration: BoxDecoration(
					color: Theme.of(context).scaffoldBackgroundColor,
					border: Border.all(
						color: Theme.of(context).colorScheme.secondary,
						width: 0.5
					),
					borderRadius: BorderRadius.circular(5)
				),
				child: Center(
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								Icons.check,
								color: Theme.of(context).colorScheme.secondary,
								size: 20,
							),
							const Gap(5),
							Text(
								message,
								textAlign: TextAlign.center,
								style: sousText(),
							),
						],
					)
				)
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: Stack(
				children: [
					Positioned.fill(
						child: Transform.scale(
								scale: 1,
								child: Image.asset(
									"src/images/contentBack.png",
									fit: BoxFit.cover,
								),
							),
					),
					SizedBox(
						height: MediaQuery.sizeOf(context).height,
						child: SingleChildScrollView(
							child: Column(
								children: [
									const Gap(105),
									detailsPart(),
									const Gap(5),
									descripZone(),
									const Gap(10),
									downloadZone(),
								],
							),
						),
					),
					Secondtop(
						title: widget.datas[widget.movie ? 'title' : 'name'],
						leftWord: widget.leftWord,
						color: Theme.of(context).primaryColor.withOpacity(0.5),
						icon: Icons.movie_edit,
						func: () => showCupertinoModalPopup(
							context: context,
							filter: ImageFilter.blur(
								sigmaX: 10,
								sigmaY: 10
							),
							builder: (context) => PopUpTemplate(
								padding: MediaQuery.sizeOf(context).height * 18 / 100,
								heigth: 240,
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
									child: modalUI(context)
								)
							)
						)
					),
				],
			)
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone note utilisateur
	Widget popularityZone() {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				selectIcon(widget.datas['vote_average'], context),
				const Gap(5),
				Text(
					widget.datas['vote_average'].toString(),
					style: TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w400,
						color: Theme.of(context).colorScheme.secondary
					),
				)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie droite de la présentation avec toutes les infos importante
	Widget rightDetailsPart() {
		print(widget.datas['seasons']);
		return SizedBox(
			height: MediaQuery.sizeOf(context).width * 0.38 * 1.5,
			width: MediaQuery.sizeOf(context).width * 0.47,
			child: Column(
				mainAxisAlignment: MainAxisAlignment.end,
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					titleText(), 
					const Gap(5),
					Text(
						widget.movie
							? (widget.datas['release_date'] != null &&
									widget.datas['release_date'].toString().split('-').length >= 2)
								? "${widget.datas['release_date'].toString().split('-').sublist(0, 2).join('/')} - ${minToHour(widget.datas['runtime'])} - ${widget.datas['origin_country'][0]}"
								: "Date inconnue - ${minToHour(widget.datas['runtime'])} - ${widget.datas['origin_country'][0]}"
							: (widget.datas['first_air_date'] != null &&
									widget.datas['first_air_date'].toString().split('-').isNotEmpty)
								? "${widget.datas['first_air_date'].toString().split('-')[0]} - ${(widget.datas['seasons'] as List).where((season) => season['season_number'] > 0).length} saisons - ${widget.datas['origin_country'][0]}"
								: "Date inconnue - ${(widget.datas['seasons'] as List).length} saisons - ${widget.datas['origin_country'][0]}",
						style: sousText(),
					),
					const Gap(3),
					if (widget.movie)
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								numberWithCom(widget.datas['budget']),
								style: sousText(),
							),
							const Gap(3),
						],
					),
					popularityZone(),
				],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// première partie de page présentant l'oeuvre
	Widget detailsPart() {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: Row(
				children: [
					SizedBox(
						width: MediaQuery.sizeOf(context).width * 0.38,
						child: Container(
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(8),
								border: Border.all(
									color: Theme.of(context).dividerColor,
									width: 0.5
								)
							),
							child: ClipRRect(
								borderRadius: BorderRadius.circular(8), 
								child: widget.img
							),
						),
					),
					const Gap(10),
					rightDetailsPart()
				],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie affichant la description
	Widget descripZone() {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: ReadMoreText(
				trimExpandedText: " Lire moins",
				trimCollapsedText: "Lire plus",
				widget.datas['overview'],
				moreStyle: TextStyle(
					color: Theme.of(context).colorScheme.tertiary,
					fontSize: 13,
					fontStyle: FontStyle.italic,
					fontWeight: FontWeight.w500
				),
				lessStyle: TextStyle(
					color: Theme.of(context).colorScheme.tertiary,
					fontSize: 13,
					fontStyle: FontStyle.italic,
					fontWeight: FontWeight.w500
				),
				style: TextStyle(
					color: Theme.of(context).colorScheme.secondary,
					fontSize: 13,
					fontWeight: FontWeight.w500
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie gérant l'affichage du YggGestionnary ou des messages de téléchargement
	Widget downloadZone() {
		return ValueListenableBuilder<Map<String, dynamic>>(
			valueListenable: mainKey.currentState!.dataStatusNotifier,
			builder: (context, dataStatus, child) {
				return AnimatedCrossFade(
						firstChild: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 10),
								child: SourceGestionnary(
									key: ValueKey(searchName),
									originalName: originalName,
									name: searchName,
									selectData: widget.datas,
									movie: widget.movie,
									func: () {
										Future.delayed(
											const Duration(seconds: 2),
											() => CupertinoActivityIndicator(
												radius: 20,
												color: Theme.of(context).colorScheme.secondary,
											)
										);
										setState(() {});
									}
								),
						),
						secondChild: AnimatedCrossFade(
							duration: const Duration(milliseconds: 300),
							firstChild: alreadyInDB("En cours de téléchargement ! C'est pour bientôt."),
							secondChild: alreadyInDB("Contenue déjà téléchargé. Bon visionnage !"),
							crossFadeState: dataStatus["queue"][widget.datas['id'].toString()] != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
						),
						crossFadeState: isDownload(dataStatus) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
						duration: const Duration(milliseconds: 300),
					);
			},
		);
	}

	///////////////////////////////////////////////////////////////
	/// Modal PopUp permettant l'édition de la recherche de film
	Widget modalUI(BuildContext modalContext) {
		return Column(
			children: [
				Align(
					alignment: Alignment.centerLeft,
					child: Text(
						"Plus de détails ?",
						style: TextStyle(
							fontSize: 20,
							fontWeight: FontWeight.w700,
							color: Theme.of(context).colorScheme.secondary
						),
					),
				),
				const Gap(20),
				SizedBox(
					height: 45,
					child: TextField(
						controller: controller,
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
				),
				const Gap(50), 
				Align(
					alignment: Alignment.bottomRight,
					child: ElevatedButton(
						onPressed: () {
							setState(() {
								searchName = controller.text;
							});
							Navigator.pop(modalContext);
						},
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).primaryColor,
							foregroundColor: Theme.of(context).colorScheme.secondary,
							padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(10),
								side: BorderSide(
									color: Theme.of(context).colorScheme.secondary,
									width: 1
								)
							)
						),
						child: Text(
							"Valider",
							style: TextStyle(
								color: Theme.of(context).colorScheme.secondary,
								fontSize: 16,
								fontWeight: FontWeight.w600
							),
						),
					),
				),
			],
		);
	}

	bool isDownload(Map<String, dynamic> dataStatus)
	{
		final id = widget.datas['id'].toString();
		if (widget.movie) {
			if (dataStatus["movie"][id] == null && dataStatus["queue"][id] == null) {
				return true;
			} 
		} else {
			List<int> alreadyIn = [];
			int nbSeasons = 0;
			if (dataStatus['queue'][id] != null) return false;
			if (dataStatus['tv'][id] != null) {
				alreadyIn = (dataStatus['tv'][id]["seasons"] as Map<String, dynamic>)
					.entries
					.where((entry) => entry.value["complete"] == true)
					.map((entry) => int.parse(entry.key.substring(1)))
					.toList()
					..sort();
			}
			for (int x = 0; x < widget.datas['seasons'].length; x++) {
				if (widget.datas['seasons'][x]['season_number'] > 0) nbSeasons++;
			}
			if (alreadyIn.length != nbSeasons) return true;
		}
		return false;
	}
}