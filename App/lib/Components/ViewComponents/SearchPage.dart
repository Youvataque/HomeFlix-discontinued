import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/FondamentalAppCompo/SecondTop.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Data/TmdbServices.dart';
import 'dart:async';

///////////////////////////////////////////////////////////////
/// composant de la searchBar custom
class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
	TextEditingController query = TextEditingController();
	Timer? _debounce;

	@override
	void dispose() {
	_debounce?.cancel();
	query.dispose();
	super.dispose();
	}

	void _onSearchChanged() {
	if (_debounce?.isActive ?? false) _debounce?.cancel();
		_debounce = Timer(const Duration(milliseconds: 500), () {
			setState(() {});
		});
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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: Stack(
				children: [
					FutureBuilder(
						future: TMDBService().searchMovies(query.text),
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
								return Padding(
									padding: const EdgeInsets.only(top: 50),
									child: searchContent(results)
								);
							}
						},
					),
					Secondtop(
						title: "osef",
						leftWord: "osed",
						color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
						searchMode: true,
						searchZone: [
							const Gap(10),
							topSearchBar(),
							const Gap(20),
							InkWell(
								onTap: () => Navigator.pop(context),
								child: Text(
									"Annuler",
									style: TextStyle(
										color: Theme.of(context).colorScheme.secondary
									),
								)
							),
							const Gap(10),
						],
					)
				],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// composant affichant les résultats de la recherche
	Widget searchContent(List<dynamic> results) {
		return ListView.builder(
			itemCount: results.length,
			shrinkWrap: true,
			itemBuilder: (context, index) {
				final result = results[index];
				final img = result['poster_path'] != null ? TMDBService().createImg(
					result['id'].toString(),
					100,
					result['media_type'] == "movie" ? true : false,
					2 / 3,
					false,
					"500"
				) :  const SizedBox.shrink();
				return result['poster_path'] != null ?
						Padding(
							padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
							child: SizedBox(
								height: 1.5 * 100,
								child: imgButton(
									img,
									result,
									result['media_type'] == "movie" ? true : false,
									query.text
								),
							)
						)
					:
						const SizedBox.shrink();
			},
		);
	}

	///////////////////////////////////////////////////////////////
	/// appBar custom pour la recherche
	Expanded topSearchBar() {
		return Expanded(
			child: SizedBox(
				height: 35,
				child: TextField(
					controller: query,
					onChanged: (word) => _onSearchChanged(),
					style: TextStyle(color: Theme.of(context).colorScheme.secondary),
					decoration: InputDecoration(
						prefixIcon: Icon(
							CupertinoIcons.search,
							color: Theme.of(context).colorScheme.secondary,
							size: 20,
						),
						contentPadding: const EdgeInsets.only(left: 0),
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
		);
	}

	///////////////////////////////////////////////////////////////
	/// affiche la seconde ligne du résultat de recherche
	Row imgButtonSecondLine(Map<String, dynamic> selectData, bool movie) {
		return Row(
			children: [
				Icon(
					CupertinoIcons.heart_fill,
					color: Theme.of(context).colorScheme.secondary,
					size: 18,
				),
				const Gap(5),
				Text(
					selectData['vote_average'].toString(),
					style: sousText()
				),
				const Gap(10),
				Text(
					"-",
					style: sousText(),
				),
				const Gap(10),
				Text(
					movie ? 
							(selectData['release_date'] != null && selectData['release_date'].toString().split('-').length >= 2) ? 
									selectData['release_date'].toString().split('-').sublist(0, 2).join('/')
								: 
									'Date inconnue'
						:
							(selectData['first_air_date'] != null && selectData['first_air_date'].toString().split('-').length >= 2) ? 
									selectData['first_air_date'].toString().split('-').sublist(0, 2).join('/')
								: 
									'Date inconnue',
					style: sousText()
				),
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// Bouton image avec un enfant custom
	Widget imgButton(Widget img, Map<String, dynamic> selectData, bool movie, String leftWord) {
		return SizedBox(
			height: 150,
			width: MediaQuery.sizeOf(context).width,
			child: InkWell(
				onTap: () => toContentView(context, selectData, img, movie, leftWord),
				child: Row(
					children: [
						const Gap(10),
						Container(
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(4),
								border: Border.all(
									color: Theme.of(context).dividerColor,
									width: 0.5
								)
							),
							child: ClipRRect(
								borderRadius: BorderRadius.circular(4), 
								child: img
							),
						),
						const Gap(10),
						Expanded(
							child: Column(
								mainAxisAlignment: MainAxisAlignment.end,
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										selectData[selectData['media_type'] == "movie" ? 'title' : 'name'],
										maxLines: 2,
										style: TextStyle(
											color: Theme.of(context).colorScheme.secondary,
											fontWeight: FontWeight.w600,
											fontSize: 16
										),
									),
									imgButtonSecondLine(selectData, movie),
									const Gap(5),
									Text(
										selectData['overview'],
										maxLines: 4,
										overflow: TextOverflow.ellipsis,
										style: sousText(),
										strutStyle: const StrutStyle(
											forceStrutHeight: true,
											height: 1.2
										),
									)
								],
							),
						),
						const Gap(10)
					],
				),
			),
		);
	}
}