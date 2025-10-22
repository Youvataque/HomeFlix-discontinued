import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/EpTemplate.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoPlayer.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoProxyServer.dart';
import 'package:homeflix/Data/NightServices.dart';
import 'package:collection/collection.dart';

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
		final bigDataSeasons = widget.bigData['seasons'];
		if (bigDataSeasons is! List) return;

		for (int x = 0; x < bigDataSeasons.length; x++) {
			final seasonInfo = bigDataSeasons.elementAtOrNull(x);
			if (seasonInfo is! Map<String, dynamic>) continue;

			final seriesNb = seasonInfo['season_number'];
			if (seriesNb is! int || seriesNb <= 0) continue;

			final serverSeasons = widget.serveurData['seasons'];
			if (serverSeasons is! Map<String, dynamic>) continue;

			final serverSeasonData = serverSeasons['S$seriesNb'];
			if (NIGHTServices().checkDlSeason(serverSeasonData)) {
				seasons.add(seriesNb);
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
		final serverSeasons = widget.serveurData['seasons'];
		final currentServerSeason = (serverSeasons is Map<String, dynamic>) ? serverSeasons['S$season'] : null;
		final isComplete = (currentServerSeason is Map<String, dynamic> && currentServerSeason['complete'] == true);

		final seasonContent = widget.seasContent.elementAtOrNull(season - 1);
		final episodesInSeason = (seasonContent is Map<String, dynamic>) ? seasonContent['episodes'] : null;
		if (episodesInSeason is! List) {
			return const SizedBox.shrink();
		}

		final serverEpisodes = (currentServerSeason is Map<String, dynamic>) ? currentServerSeason['episode'] : null;
		final downloadedEpisodes = (serverEpisodes is List) ? serverEpisodes : [];

		final int episodeCount = isComplete ? episodesInSeason.length : downloadedEpisodes.length;

		return Column(
			key: ValueKey(season),
			children: List.generate(
				episodeCount,
				(index) {
					final episodeNumber = isComplete ? index + 1 : (downloadedEpisodes.elementAtOrNull(index) as int? ?? -1);
					if (episodeNumber == -1) return const SizedBox.shrink();

					final episodeData = episodesInSeason.elementAtOrNull(episodeNumber - 1);
					if (episodeData is! Map<String, dynamic>) return const SizedBox.shrink();

					final stillPath = episodeData['still_path'] as String?;
					final imgPath = stillPath != null
							? "https://image.tmdb.org/t/p/w300/$stillPath?api_key=${dotenv.get('TMDB_KEY')}"
							: null;

					return Padding(
						padding: EdgeInsets.only(
							bottom: index == episodeCount - 1 ? 0 : 20,
						),
						child: Eptemplate(
							index: episodeNumber - 1,
							time: episodeData['runtime'] as int? ?? 0,
							title: episodeData['name'] as String? ?? "Titre inconnu",
							imgPath: imgPath,
							overview: episodeData['overview'] as String?,
							id: "${widget.bigData['id']}_${seasonContent?['_id']}_${episodeData['id']}",
							onTap: () => onEpTap(episodeNumber)
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
			if (mounted) infoDialog(context, "Path non trouvé, annulation.", true);
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