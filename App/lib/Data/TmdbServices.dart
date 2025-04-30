import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeflix/Components/ViewComponents/CachedImgWidget.dart';
import 'package:http/http.dart' as http;

final fourMonthsAgo = DateTime.now().subtract(const Duration(days: 120)).toIso8601String();

///////////////////////////////////////////////////////////////
/// gestionnaire de téléchargement TMDB API
class TMDBService {
	static List<Map<String, dynamic>> the10movieTren = [];
	static List<Map<String, dynamic>> the20movieRecent = [];
	static List<Map<String, dynamic>> the20moviePop = [];
	static List<Map<String, dynamic>> movieCateg = [];

	static List<Map<String, dynamic>> the10serieTren = [];
	static List<Map<String, dynamic>> the20seriePop = [];
	static List<Map<String, dynamic>> the20serieTop = [];
	static List<Map<String, dynamic>> serieCateg = [];

	///////////////////////////////////////////////////////////////
	/// Fonction pour récupérer les têtes d'affiche (films aléatoires)
	Future<List<Map<String, dynamic>>> fetchContent(int count, String link, int randomNb) async {
		final List<Map<String, dynamic>> movies = [];
		final random = Random();

		while (movies.length < count) {
			final int randomPage = randomNb == -1 ? random.nextInt(15) + 1 : randomNb;
			final response = await http.get(
				Uri.parse("$link${count != 1 ? "&page=$randomPage" : ""}"),
			);
			if (response.statusCode == 200) {
				final data = json.decode(response.body);
				final List<dynamic> results = count != 1 ? data['results'] : [data];
				movies.addAll(results.map((e) => e as Map<String, dynamic>));
				if (randomNb != -1) break;
			} else {
			}
		}
		return movies;
	}

	///////////////////////////////////////////////////////////////
	/// Fonction pour update une liste d'élément et y ajouter une nouvelle page
	Future<List<Map<String, dynamic>>> addMore(String link, List<Map<String, dynamic>> data) async {
		int newPage = (data.length ~/ 20) + 1; 
		final newData = await fetchContent(20, link, newPage); 
		data.addAll(newData);
		return data;
	}
	
	///////////////////////////////////////////////////////////////
	/// Télécharge les images des films
	Future<File?> downloadMovieImageTemp(String imageUrl, String movieId, int mode) async {
		String type = "";
		try {
			final response = await http.get(Uri.parse(imageUrl));
			if (mode == 1) {type = "b";}
			else if (mode == 2) {type = "s";}
			else {type = "";}
			if (response.statusCode == 200) {
				final bytes = response.bodyBytes;
				final tempDir = Directory.systemTemp;
				final file = File('${tempDir.path}/$movieId$type.jpg');
				await file.writeAsBytes(bytes);
				return file;
			} else {
				print('Failed to download image from: $imageUrl');
				return null;
			}
		} catch (e) {
			print('Error downloading image from: $imageUrl, Error: $e');
			return null;
		}
	}

	///////////////////////////////////////////////////////////////
	/// Télécharge les image poster ou renvoi un message si non présent
	Future<File?> fetchAndDownloadMovieImage(String movieId, bool movie, String quality) async {
		final apiKey = dotenv.get('TMDB_KEY');
		final url = 'https://api.themoviedb.org/3/${movie ? "movie" : "tv"}/$movieId?api_key=$apiKey';
		final response = await http.get(Uri.parse(url));

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			final posterPath = data['poster_path'];
			if (posterPath != null) {
				final imageUrl = 'https://image.tmdb.org/t/p/w$quality$posterPath';
				return await downloadMovieImageTemp(imageUrl, movieId.toString(), 0);
			} else {
				print('Aucune image trouvée pour le film avec ID: $movieId');
				return null;
			}
		} else {
			print('Erreur lors de la récupération des détails du film: ${response.statusCode}');
			return null;
		}
	}

	///////////////////////////////////////////////////////////////
	/// Télécharge les images de fond ou renvoi un message si non présent
	Future<File?> fetchAndDownloadMovieBackdrop(String movieId, bool isMovie, String quality) async {
		final apiKey = dotenv.get('TMDB_KEY');
		final url = 'https://api.themoviedb.org/3/${isMovie ? "movie" : "tv"}/$movieId/images?api_key=$apiKey';

		final response = await http.get(Uri.parse(url));

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			final backdrops = data['backdrops'] as List<dynamic>;

			if (backdrops.isNotEmpty) {
			final backdropPath = backdrops[0]['file_path'];
			if (backdropPath != null) {
				final imageUrl = 'https://image.tmdb.org/t/p/w$quality$backdropPath';
				return await downloadMovieImageTemp(imageUrl, movieId.toString(), 1);
			}
			}
			print('Aucun paysage trouvé pour le film avec ID: $movieId');
			return null;
		} else {
			print('Erreur lors de la récupération des images: ${response.statusCode}');
			return null;
		}
	}

	///////////////////////////////////////////////////////////////
	/// crée une image à partir de la DB ou des fichiers interne vie futureBuilder
	Widget createImg(String movieId, double width, bool movie, double aspectRatio, bool mode, String quality) {
		return CachedImageWidget(
			movieId: movieId,
			width: width,
			movie: movie,
			aspectRatio: aspectRatio,
			mode: mode,
			quality: quality,
		);
	}

	Future<File?> getImgWithPath(String path, String id) async {
		final tempDir = Directory.systemTemp;
		final file = File('${tempDir.path}/${id}s.jpg');

		if (await file.exists()) {
			return file;
		} else {
			print('Downloading image from: $path');
			return downloadMovieImageTemp(path, id, 2);
		}
	}

	///////////////////////////////////////////////////////////////
	/// recupère l'image dans la db si elle n'est pas déjà présente en mémoire sans fournir le path
	Future<File?> getImgWithoutPath(String movieId, bool movie, bool mode, String quality) async {
		final tempDir = Directory.systemTemp;
		final file = File('${tempDir.path}/$movieId${mode ? 'b' : ''}.jpg');

		if (await file.exists()) {
			return file;
		} else {
			return mode ? fetchAndDownloadMovieBackdrop(movieId, movie, quality) : fetchAndDownloadMovieImage(movieId, movie, quality);
		}
	}

	///////////////////////////////////////////////////////////////
	/// récupère les catégories des films / series
	Future<List<Map<String, dynamic>>> fetchCateg(bool movie) async {
		final List<Map<String, dynamic>> temp = [];
		final response = await http.get(
			Uri.parse('https://api.themoviedb.org/3/genre/${movie ? 'movie' : 'tv'}/list?api_key=${dotenv.get('TMDB_KEY')}&language=fr'),
		);

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			final List<dynamic> results = data['genres'];

			temp.addAll(results.take(results.length).map((e) => e as Map<String, dynamic>));
		} else {
			throw Exception('Failed to load movies');
		}
		return temp;
	}

	///////////////////////////////////////////////////////////////
	/// télécharge des films à partir d'une recherche
	Future<List<dynamic>> searchMovies(String query) async {
		final url = 'https://api.themoviedb.org/3/search/multi?query=$query&include_adult=false&api_key=${dotenv.get('TMDB_KEY')}&language=fr-FR';
		final response = await http.get(Uri.parse(url));

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			return data['results'];
		} else {
			throw Exception('Erreur lors du chargement des données');
		}
	}

	///////////////////////////////////////////////////////////////
	/// récupère les détails d'un film
	Future<Map<String, dynamic>> fetchSerieDetails(int serieId, int seasonNb) async {
		final url = "https://api.themoviedb.org/3/tv/$serieId/season/$seasonNb?language=fr-FR&api_key=${dotenv.get('TMDB_KEY')}";

		try {
			final response = await http.get(Uri.parse(url));

			if (response.statusCode == 200) {
				final data = json.decode(response.body) as Map<String, dynamic>;
				return data;
			} else {
				print("Erreur HTTP ${response.statusCode} : ${response.reasonPhrase}");
				throw Exception("Erreur lors de la récupération des détails de la série.");
			}
		} catch (e) {
			print("Erreur : $e");
			throw Exception("Impossible de récupérer les détails de la série.");
		}
	}
}