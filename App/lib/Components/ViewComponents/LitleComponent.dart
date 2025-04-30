import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeflix/Components/ViewComponents/CategView.dart';
import 'package:homeflix/Components/ViewComponents/ContentPages/ContentView.dart';
import 'package:homeflix/Data/TmdbServices.dart';

///////////////////////////////////////////////////////////////
/// ombre de l'app
BoxShadow myShadow(BuildContext context) {
	return BoxShadow(
    	color: Theme.of(context).shadowColor.withOpacity(0.3),
		blurRadius: 5
	);
}

///////////////////////////////////////////////////////////////
/// Transfert vers la page content View (la page de téléchargement)
void toContentView(BuildContext context, Map<String, dynamic> datas, Widget img, bool movie, String leftWord) async {
	List<Map<String, dynamic>> bigData = await TMDBService().fetchContent(1, "https://api.themoviedb.org/3/${movie ? "movie" : "tv"}/${datas['id']}?api_key=${dotenv.get('TMDB_KEY')}&language=fr-FR", 1);
	Navigator.push(
		context,
		MaterialPageRoute(builder: (context) => Contentview(
			datas: bigData.first,
			img: img,
			movie: movie,
			leftWord: leftWord,
		))
	);
}

///////////////////////////////////////////////////////////////
/// transfert vers la page de catégorie (la page de recherche)
void toCategView(BuildContext context, Map<String, dynamic> details, String leftWord, bool movie) async {
	List<Map<String, dynamic>> favData = await TMDBService().fetchContent(20, 'https://api.themoviedb.org/3/discover/${movie ? 'movie' : 'tv'}?api_key=${dotenv.get('TMDB_KEY')}&with_genres=${details['id']}&vote_count.gte=100&sort_by=vote_average.desc&language=fr-FR', -1);
	List<Map<String, dynamic>> allData = await TMDBService().fetchContent(20, 'https://api.themoviedb.org/3/discover/${movie ? 'movie' : 'tv'}?api_key=${dotenv.get('TMDB_KEY')}&with_genres=${details['id']}include_adult=false&include_null_first_air_dates=false&language=fr-FR&page=1&sort_by=first_air_date.desc&vote_count.gte=100', 1);
	Navigator.push(
		context,
		MaterialPageRoute(builder: (context) => Categview(
			details: details,
			leftWord: leftWord,
			allData: allData,
			favData: favData,
			movie: movie
		))
	);
}

///////////////////////////////////////////////////////////////
	/// selection du message de popularité
	String selectMesage(double percent) {
		percent = (percent * 10).round() / 10;
		if (percent >= 8) {
			return "Cette oeuvre est un immanquable : $percent";
		} else if (percent >= 6) {
			return "Une oeuvre appréciée : $percent";
		} else if (percent >= 5) {
			return "Une oeuvre plutôt appréciée : $percent";
		} else {
			return "On a fait mieux : $percent";
		}
	}
	
	///////////////////////////////////////////////////////////////
	/// selection de l'icon de popularité
	Icon selectIcon(double percent, BuildContext context) {
		percent = (percent * 10).round() / 10;
		if (percent >= 8) {
			return const Icon(
				CupertinoIcons.star_fill,
				color: Colors.yellow,
				size: 16,
			);
		} else if (percent >= 6) {
			return Icon(
				CupertinoIcons.heart_fill,
				color: Theme.of(context).colorScheme.tertiary,
				size: 16,
			);
		} else if (percent >= 5) {
			return const Icon(
				CupertinoIcons.hand_thumbsup_fill,
				color: Colors.blue,
				size: 16,
			);
		} else {
			return const Icon(
				CupertinoIcons.hand_thumbsdown_fill,
				color: Colors.red,
				size: 16,
			);
		}
	}

	///////////////////////////////////////////////////////////////
	/// affiche une roue de chargement
	CupertinoActivityIndicator myIndicator(BuildContext context, int radius) {
		return CupertinoActivityIndicator(
			radius: radius.toDouble(),
			color: Theme.of(context).colorScheme.secondary,	
		);
	}