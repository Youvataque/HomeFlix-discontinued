import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeflix/Components/FondamentalAppCompo/MyTabbar.dart';
import 'package:homeflix/Components/Logins/Login.dart';
import 'package:homeflix/Components/Tools/Theme/ColorsTheme.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Data/NightServices.dart';
import 'package:homeflix/Data/TmdbServices.dart';
import 'firebase_options.dart';


GlobalKey<MainState> mainKey = GlobalKey<MainState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await Firebase.initializeApp(
		options: DefaultFirebaseOptions.currentPlatform,
	);
 	await dotenv.load(fileName: ".env");
	SystemChrome.setPreferredOrientations([
		DeviceOrientation.portraitUp,
		DeviceOrientation.portraitDown,
	]);
    HttpOverrides.global = MyHttpOverrides();
   runApp(Main(key: mainKey));
}

class Main extends StatefulWidget {
	const Main({super.key});

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
	Timer? _timer;
	int	refreshKey = 0;
	ValueNotifier<Map<String, dynamic>> dataStatusNotifier = ValueNotifier<Map<String, dynamic>>({});

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////// lancement nettoyage

	@override
	void initState() {
		super.initState();
		_startPeriodicFetch();
	}

	@override
	void dispose() {
		_timer?.cancel();
		dataStatusNotifier.dispose();
		super.dispose();
	}

	void refreshData() async {
		_timer?.cancel();
		dataStatusNotifier.dispose();
		dataStatusNotifier = ValueNotifier<Map<String, dynamic>>({});
		_startPeriodicFetch();
		if (mounted) {
			setState(() {
				refreshKey++;
			});
		}
		await downloadData();
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////// téléchargement des datas (toutes les 4s)

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
			home: FutureBuilder(
				key: ValueKey(refreshKey),
				future: downloadData(),
				builder: (context, snapshot) {
					if (snapshot.connectionState == ConnectionState.waiting) {
						return myIndicator(context, 20);
					} else if (snapshot.connectionState == ConnectionState.done) {
						if (snapshot.data ?? false) {
							return const MyTabbar();
						} else {
							return const Login();
						}
					} else {
						return const Text("error");
					}
				}
			)
		);
	}

	///////////////////////////////////////////////////////////////
	/// vérifie que l'utilisateur est autorisé / existant
	Future<bool> isUserLoggedIn() async {
		final user = FirebaseAuth.instance.currentUser;
		if (user != null) {
			try {
				await user.reload();
				await user.getIdToken(true);
				return true;
			} catch (e) {
				print("🚨 Utilisateur désactivé ou problème de token : $e");
				await FirebaseAuth.instance.signOut();
				return false;
			}
		}
		return false;
	}

	///////////////////////////////////////////////////////////////
	/// Télécharge les données de l'api TMDB en utilisant le gestionnaire custom TMDBService
	Future<bool> downloadData() async {
		if (await isUserLoggedIn()) {
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
		}
		return isUserLoggedIn();
	}
}
