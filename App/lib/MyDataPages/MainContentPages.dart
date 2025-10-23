import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Tools/FormatTool/MinToHour.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Data/TmdbServices.dart';
import 'package:homeflix/MyDataPages/MoviePages.dart';
import 'package:homeflix/MyDataPages/SeriesPages.dart';
import 'package:readmore/readmore.dart';

///////////////////////////////////////////////////////////////
/// widget de présentation de chaques oeuvres téléchargés
class MainContentPages extends StatefulWidget {
	final Map<String, dynamic> serveurData;
	final Map<String, dynamic> bigData;
	final String id;
	final bool movie;
	final VoidCallback onClose;
	const MainContentPages({
		super.key,
		required this.serveurData,
		required this.bigData,
		required this.id,
		required this.movie,
		required this.onClose
	});

	@override
	State<MainContentPages> createState() => _MainContentPagesState();
}

class _MainContentPagesState extends State<MainContentPages> {
	List<Map<String, dynamic>> seasContent = [];
	Future<void>? _fetchFuture;

	@override
	void initState() {
		super.initState();
		if (!widget.movie) _fetchFuture = fetchAll();
	}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des sous composants

	///////////////////////////////////////////////////////////////
	/// bouton de retour
	Container backButton() {
		return Container(
			width: 30,
			height: 30,
			decoration: BoxDecoration(
				color: Theme.of(context).scaffoldBackgroundColor,
				borderRadius: BorderRadius.circular(30)
			),
			child: IconButton(
				padding: EdgeInsets.zero,
				iconSize: 20,
				onPressed: () => widget.onClose(),
				icon: Icon(
					Icons.close,
					color: Theme.of(context).colorScheme.secondary,
				)
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// UI titre de l'oeuvre
	Padding titleText(String title) {
		return Padding(
			padding: const EdgeInsets.only(
				left: 8,
				right: 8,
				top: 8,
			),
			child: Align(
				alignment: Alignment.centerLeft,
				child:  Text(
					title,
					style: TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w700,
						color: Theme.of(context).colorScheme.secondary
					),
				)
			),
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des composants

	//////////////////////////////////////////////////////////////////
	/// corp du code
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: SizedBox(
				height: MediaQuery.sizeOf(context).height,
				width: MediaQuery.sizeOf(context).width,
				child: Stack(
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
						SingleChildScrollView(
							child: Column(
								children: [
									imgTop(),
									titleText(widget.bigData[widget.movie ? "title" : "name"]),
									infoText(),
									popularityZone(),
									const Gap(5),
									completedContent(),
									const Gap(10),
									descripZone(),
									const Gap(15),
									dedicatedPages()
								],
							),
						),
						AbsorbPointer(
							absorbing: true,
							child: SizedBox(
								height: 100,
								width: MediaQuery.sizeOf(context).width,
							),
						),
						Align(
							alignment: Alignment.topRight,
							child: Padding(
								padding: const EdgeInsets.all(10),
								child: backButton()
							)
						)
					],
				),
			)
		);
	}

	///////////////////////////////////////////////////////////////
	/// UI info text
	Padding infoText() {
		return Padding(
			padding: const EdgeInsets.only(
				left: 8,
				right: 8,
				top: 2,
			),
			child: Align(
				alignment: Alignment.centerLeft,
				child: Text(
					widget.movie
							? (widget.bigData['release_date'] != null &&
									widget.bigData['release_date'].toString().split('-').length >= 2)
								? "${widget.bigData['release_date'].toString().split('-').sublist(0, 2).join('/')} - ${minToHour(widget.bigData['runtime'])} - ${widget.bigData['origin_country'][0]}"
								: "Date inconnue - ${minToHour(widget.bigData['runtime'])} - ${widget.bigData['origin_country'][0]}"
							: (widget.bigData['first_air_date'] != null &&
									widget.bigData['first_air_date'].toString().split('-').isNotEmpty)
								? "${widget.bigData['first_air_date'].toString().split('-')[0]} - ${(widget.bigData['seasons'] as List).where((season) => season['season_number'] > 0).length} saisons - ${widget.bigData['origin_country'][0]}"
								: "Date inconnue - ${(widget.bigData['seasons'] as List).length} saisons - ${widget.bigData['origin_country'][0]}",
					style: TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w400,
						color: Theme.of(context).colorScheme.secondary
					),
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie haute comprenant backdropImg + backButton
	Widget imgTop() {
		return TMDBService().createImg(
					widget.id,
					MediaQuery.of(context).size.width,
					widget.movie,
					16 / 9,
					true,
					"1280"
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone note utilisateur
	Widget popularityZone() {
		return Padding(
			padding: const EdgeInsets.only(left: 8, right: 8),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					selectIcon(widget.bigData['vote_average'], context),
					const Gap(5),
					Text(
						selectMesage(widget.bigData['vote_average']),
						style: TextStyle(
							fontSize: 14,
							fontWeight: FontWeight.w400,
							color: Theme.of(context).colorScheme.secondary
						),
					)
				],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone d'affichage de la complétion de la série
	Widget completedContent() {
		if (!widget.movie) {
			int seasonCount =  0;
			for (int x = 0; x < widget.bigData['seasons'].length; x++) {
				if (widget.bigData['seasons'][x]['season_number'] > 0) seasonCount++;
			}
			Map<String, dynamic> seasons = widget.serveurData['seasons'];
			int nbseasons = seasons.entries
				.where((entry) => entry.value["complete"] == true)
				.map((entry) => int.parse(entry.key.substring(1)))
				.toList()
				.length;
			bool isComplete = nbseasons == seasonCount;
			return Align(
				alignment: Alignment.topLeft,
				child: Padding(
					padding: const EdgeInsets.only(left: 8, right: 8),
					child: Container(
						height: 27.5,
						width: isComplete ? 140 : 160,
						decoration: BoxDecoration(
							color: isComplete ? Colors.green: const Color.fromRGBO(229, 72, 77, 1),
							borderRadius: BorderRadius.circular(5)
						),
						child: Center(
							child: Text(
								isComplete ? "Série complète  ✓" : "Série incomplète : $nbseasons/$seasonCount",
								style: TextStyle(
									fontSize: 13,
									fontWeight: FontWeight.w600,
									color: Theme.of(context).colorScheme.secondary
								),
							),
						),
					),
				),
			);
		}
		return const SizedBox.shrink();
	}

	//////////////////////////////////////////////////////////////
	/// partie affichant la description
	Widget descripZone() {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: ReadMoreText(
				trimExpandedText: " Lire moins",
				trimCollapsedText: "Lire plus",
				widget.bigData['overview'],
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

	//////////////////////////////////////////////////////////////
	/// renvoie vers la page dédiée
	Widget dedicatedPages() {
		return widget.movie ? 
				MoviePages(
          			id: widget.id,
					serveurData: widget.serveurData,
					movie: widget.movie,
				)
			: 
				FutureBuilder(
					future: _fetchFuture,
					builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
						if (snapshot.connectionState == ConnectionState.waiting) {
							return myIndicator(context, 10);
						} else {
							return SeriesPages(
                				id: widget.id,
								serveurData: widget.serveurData,
								bigData: widget.bigData,
								seasContent: seasContent,
								movie: widget.movie,
							);
						}
					},
				);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des fonctions

	///////////////////////////////////////////////////////////////
	/// récupération des données par saison
	Future<bool> fetchAll() async {
		for (int x = 0; x < widget.bigData['seasons'].length; x++) {
			if (widget.bigData['seasons'][x]['season_number'] > 0) {
				final seasonTemp = await TMDBService().fetchSerieDetails(
					int.parse(widget.id),
					widget.bigData['seasons'][x]['season_number']
				);
				seasContent.add(seasonTemp);
			}
		}
		return true;
	}
	
}