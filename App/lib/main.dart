import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeflix/Components/FondamentalAppCompo/MyTabbar.dart';
import 'package:homeflix/Components/FondamentalAppCompo/Settings.dart';
import 'package:homeflix/Components/Tools/Theme/ColorsTheme.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Data/KeyServices.dart';
import 'package:homeflix/Data/NightServices.dart';
import 'package:homeflix/Data/TmdbServices.dart';

late GlobalKey<MainState> mainKey;

void main() async {
	WidgetsFlutterBinding.ensureInitialized();
 	await dotenv.load(fileName: ".env");
	SystemChrome.setPreferredOrientations([
		DeviceOrientation.portraitUp,
		DeviceOrientation.portraitDown,
	]);
	mainKey = GlobalKey<MainState>();
	runApp(Main(key: mainKey));
}

class Main extends StatefulWidget {
	const Main({super.key});

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
	Timer? _timer;
	final ValueNotifier<Map<String, dynamic>> dataStatusNotifier = ValueNotifier<Map<String, dynamic>>({});
	bool connectEtablished = false;

	@override
	void initState() {
		super.initState();
		if (connectEtablished) {
			_startPeriodicFetch();
		}
	}

	@override
	void dispose() {
		_timer?.cancel();
		dataStatusNotifier.dispose();
		super.dispose();
	}

	void _startPeriodicFetch() {
		_timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
			final newDataStatus = await NIGHTServices().fetchDataStatus();
			if (!mapsAreEqual(dataStatusNotifier.value, newDataStatus)) {
				dataStatusNotifier.value = newDataStatus;
			}
		});
	}

	bool mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
		return jsonEncode(map1) == jsonEncode(map2);
	}

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			theme: darkTheme,
			darkTheme: darkTheme,
			home: FutureBuilder<bool>(
			future: loadApp(),
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.waiting) {
					return myIndicator(context, 20);
				} else if (snapshot.connectionState == ConnectionState.done) {
					if (snapshot.data == true) {
						return const MyTabbar();
					} else {
						return const Settings(leftWord: null);
					}
					} else {
						return const Text("Erreur de chargement");
					}
				},
			),
		);
	}

	Future<bool> loadApp() async {
		await Keyservices().load();
		final isValid = await NIGHTServices().testValidity();
		if (!isValid) return false;
		await downloadData();
		connectEtablished = true;
		return true;
	}

	///////////////////////////////////////////////////////////////
	/// Télécharge les données de l'api TMDB en utilisant le gestionnaire custom TMDBService
	Future<bool> downloadData() async {
		dataStatusNotifier.value = await NIGHTServices().fetchDataStatus();
		NIGHTServices.specStatus = await NIGHTServices().fetchSpecStatus();
		TMDBService.the10movieTren = await TMDBService().fetchContent(10, "https://api.themoviedb.org/3/discover/movie?api_key=${dotenv.get('TMDB_KEY')}&include_adult=false&include_video=false&language=fr-FR&primary_release_date.gte=2024-01-01&sort_by=popularity.desc", 1);
		TMDBService.the20moviePop = await TMDBService().fetchContent(20, "https://api.themoviedb.org/3/discover/movie?api_key=${dotenv.get('TMDB_KEY')}&include_adult=false&include_video=false&language=fr-FR&sort_by=popularity.desc", -1);
		TMDBService.the20movieRecent = await TMDBService().fetchContent(20, "https://api.themoviedb.org/3/discover/movie?api_key=${dotenv.get('TMDB_KEY')}&include_adult=false&include_video=false&language=fr-FR&primary_release_date.gte=2024-01-01&sort_by=popularity.desc", 2);
		TMDBService.movieCateg = await TMDBService().fetchCateg(true);
		TMDBService.the10serieTren = await TMDBService().fetchContent(10, "https://api.themoviedb.org/3/tv/on_the_air?api_key=${dotenv.get('TMDB_KEY')}&language=fr-FR", -1);		
		TMDBService.the20seriePop = await TMDBService().fetchContent(20, "https://api.themoviedb.org/3/trending/tv/day?api_key=${dotenv.get('TMDB_KEY')}&language=fr-FR&vote_average.gte=8&vote_count.gte=100", -1);
		TMDBService.the20serieTop = await TMDBService().fetchContent(20, "https://api.themoviedb.org/3/tv/top_rated?api_key=${dotenv.get('TMDB_KEY')}&language=fr-FR", 1);
		TMDBService.serieCateg = await TMDBService().fetchCateg(false);
		return true;
	}
}
