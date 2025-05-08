import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/EpTemplate.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoPlayer.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoProxyServer.dart';
import 'package:homeflix/Data/NightServices.dart';

///////////////////////////////////////////////////////////////
/// Template des pages de séries
class SeriesPages extends StatefulWidget {
  final String id;
	final Map<String, dynamic> serveurData;
	final Map<String, dynamic> bigData;
	final List<Map<String, dynamic>> seasContent;
	final bool movie;
	const SeriesPages({
		super.key,
    	required this.id,
		required this.serveurData,
		required this.bigData,
		required this.seasContent,
		required this.movie
	});

	@override
	State<SeriesPages> createState() => _SeriesPagesState();
}

class _SeriesPagesState extends State<SeriesPages> {
	int season = 1;
	List<int> seasons = [];
	VideoProxyServer videoProxy = VideoProxyServer();

	@override
	void initState() {
		super.initState();
		for (int x = 0; x < widget.bigData['seasons'].length; x++) {
			final seriesNb = widget.bigData['seasons'][x]['season_number'];
			if ( seriesNb > 0 && NIGHTServices().checkDlSeason(widget.serveurData['seasons']['S$seriesNb'])) {
				seasons.add(widget.bigData['seasons'][x]['season_number']);
			}
		}
	}

	///////////////////////////////////////////////////////////////
	/// corp du code
	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: MediaQuery.sizeOf(context).width - 16,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					seasonSelector(),
					const Gap(20),
					printEp(),
					const Gap(35),
				],
			),
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des composants

	///////////////////////////////////////////////////////////////
	/// bouton de sélection de saison
	Widget seasonSelector() {
		if (seasons.isEmpty) {
			return const SizedBox.shrink();
		}
		if (!seasons.contains(season)) {
			WidgetsBinding.instance.addPostFrameCallback((_) {
				setState(() {
				season = seasons.first;
				});
			});
		}
		return Container(
			height: 32,
			width: 110,
			decoration: BoxDecoration(
				color: Theme.of(context).primaryColor.withOpacity(0.7),
				border: Border.all(
					color: Theme.of(context).colorScheme.secondary,
					width: 0.5,
				),
				borderRadius: BorderRadius.circular(7),
			),
			child: Center(
				child: DropdownButton<int>(
					value: season,
					items: seasons.map((int season) {
						return DropdownMenuItem<int>(
							value: season,
							child: Text(
								"Saison $season",
								style: TextStyle(
									color: Theme.of(context).colorScheme.secondary,
									fontSize: 16,
								),
							),
						);
					}).toList(),
					onChanged: (int? newValue) {
						if (newValue != null) {
							setState(() {
								season = newValue;
							});
						}
					},
					dropdownColor: Theme.of(context).primaryColor,
					icon: Icon(
						Icons.arrow_drop_down,
						color: Theme.of(context).colorScheme.secondary,
						size: 24,
					),
					underline: const SizedBox(),
					borderRadius: BorderRadius.circular(10),
				),
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// affichage des épisodes
	Widget printEp() {
		final isComplete = widget.serveurData['seasons']['S$season']['complete'];
		return Column(
			key: ValueKey(season),
			children: List.generate(
				isComplete ?
						widget.seasContent[season - 1]['episodes'].length
					:
						widget.serveurData['seasons']['S$season']['episode'].length,
				(index) {
					final tempS = widget.seasContent[season - 1]['episodes'];
					final tempE = isComplete ? index : widget.serveurData['seasons']['S$season']['episode'][index];
					return Padding(
						padding: EdgeInsets.only(
							bottom: index == tempS.length - 1 ? 0 : 20,
						),
						child: Eptemplate(
							index: isComplete ? tempE : tempE - 1,
							time: tempS[tempE]['runtime'] ?? 0,
							title: tempS[tempE]['name'] ?? "inconue",
							imgPath: "https://image.tmdb.org/t/p/w300/${tempS[tempE]['still_path']}?api_key=${dotenv.get('TMDB_KEY')}",
							overview: tempS[tempE]['overview'],
							id: "${widget.bigData['id']}_${widget.seasContent[season - 1]['_id']}_${tempS[tempE]['id']}",
							onTap: () => onEpTap(isComplete ? tempE + 1 : tempE)
						),
					);
				},
			),
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des fonctions

	///////////////////////////////////////////////////////////////
	/// lance la vidéo lors de l'appuie sur un épisode
	void onEpTap(int index) async {
		final path = await NIGHTServices().searchContent(
			widget.id,
			season,
			index,
			widget.movie
		);
		if (path == null) {
			print("Path non trouvé, annulation.");
			return;
		}
		final encodedPath = Uri.encodeComponent(path);
		final videoUrl = "http://${dotenv.get('NIGHTCENTER_IP')}:4000/api/streamVideo?path=$encodedPath";
		await videoProxy.startProxy();
		final proxyUrl = await videoProxy.getProxyUrl(videoUrl);
		if (mounted) {
			Navigator.push(
					context,
					MaterialPageRoute(builder: (context) => VlcVideoPlayer(videoUrl: proxyUrl, videoProxy: videoProxy,))
			);
		}
	}
}