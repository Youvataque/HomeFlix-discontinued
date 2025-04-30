import 'dart:convert';
import 'package:homeflix/Data/KeyServices.dart';
import 'package:http/http.dart' as http;

class NIGHTServices {
	static Map<String, dynamic> dataStatus = {};
	static Map<String, dynamic> specStatus = {};

	///////////////////////////////////////////////////////////////
	/// Vérifie que l'ip et la clef permettent d'accéder au serveur, sinon renvoie au menue.
	Future<bool> testValidity() async {
		try {
			final ip = Keyservices.nightcenterIp;
			final key = Keyservices.nightcenterKey;

			if (ip.isEmpty || key.isEmpty) return false;

			final uri = Uri.parse('http://$ip:${Keyservices.nightcenterPort}/api/contentStatus?api_key=$key');
			final response = await http.get(uri).timeout(const Duration(seconds: 3));

			return response.statusCode == 200;
		} catch (e) {
			return false;
		}
	}

	///////////////////////////////////////////////////////////////
	/// méthode pour récupérer les données des contenues téléchargés sur le server
	Future<Map<String, dynamic>> fetchDataStatus() async {
		Map<String, dynamic> results = {};
		final response = await http.get(
			Uri.parse("http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/contentStatus?api_key=${Keyservices.nightcenterKey}"),
		);
		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			results = data;
		} else {
			print("error on the status -> ${response.reasonPhrase}");
		}
		return results;
	}

	///////////////////////////////////////////////////////////////
	/// méthode pour récupérer les données des contenues téléchargés sur le server
	Future<Map<String, dynamic>> fetchSpecStatus() async {
		Map<String, dynamic> results = {};
		final response = await http.get(
			Uri.parse("http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/specStatus?api_key=${Keyservices.nightcenterKey}"),
		);
		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			results = data;
		} else {
			print("error on the status -> ${response.reasonPhrase}");
		}
		return results;
	}

	///////////////////////////////////////////////////////////////
	/// Fonction pour récupérer le contenu d'une page choisie  
	/// depuis la source (C)
	Future<List<Map<String, dynamic>>> fetchQueryTorrent(int page, String name) async {
		List<Map<String, dynamic>> results = [];

		final response = await http.get(
			Uri.parse("http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/fetchTorrentContent?api_key=${Keyservices.nightcenterKey}&page=$page&name=$name"),		
		);

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			results = (data as List).map((item) => item as Map<String, dynamic>).toList();
		} else {
			print("Erreur sur la source -> ${response.reasonPhrase}");
		}
		return results;
	}

	//////////////////////////////////////////////////////////////////
	/// fonction pour envoyer la requête de téléchargement au serveur
	Future<void> sendDownloadRequest(String id, String filename) async {
		final apiUrl = 'http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/contentDl?api_key=${Keyservices.nightcenterKey}';

		try {
			
			final response = await http.post(
				Uri.parse(apiUrl),
				headers: {
					'Content-Type': 'application/json',
				},
				body: jsonEncode({
					'id': id,
					'filename': filename
				}),
			);
			if (response.statusCode == 200) {
				print('✅ Fichier téléchargé avec succès');
			} else {
				print('❌ Erreur lors du téléchargement : ${response.body}');
			}
		} catch (e) {
			print('❌ Erreur lors de la requête : $e');
		}
	}

	
	///////////////////////////////////////////////////////////////
	/// Méthode pour envoyer un contenu dans le queue de téléchargement du serveur
	Future<void> postDataStatus(Map<String, dynamic> newData, String where) async {
		final url = Uri.parse("http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/contentStatus?api_key=${Keyservices.nightcenterKey}");
		final headers = {'Content-Type': 'application/json'};
		final body = jsonEncode({'newData': newData, 'where': where});

		final response = await http.post(url, headers: headers, body: body);

		if (response.statusCode == 201) {
			print('Données ajoutées avec succès');
		} else {
			print('Erreur: ${response.statusCode}');
			print('Message: ${response.body}');
		}
	}

	///////////////////////////////////////////////////////////////
	/// Méthode pour envoyer un contenu dans le queue de téléchargement du serveur
	Future<void> deleteData(Map<String, dynamic> newData) async {
		final url = Uri.parse("http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/contentErase?api_key=${Keyservices.nightcenterKey}");
		final headers = {'Content-Type': 'application/json'};
		final body = jsonEncode({'newData': newData});

		final response = await http.post(url, headers: headers, body: body);

		if (response.statusCode == 201) {
			print('Données ajoutées avec succès');
		} else {
			print('Erreur: ${response.statusCode}');
			print('Message: ${response.body}');
		}
  	}

	///////////////////////////////////////////////////////////////
	/// Fonction pour appeler la route `contentSearch`
	Future<String?> searchContent(String id, int season, int episode, bool movie) async {
		final apiUrl = 'http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/contentSearch?api_key=${Keyservices.nightcenterKey}';

		try {
			final response = await http.post(
				Uri.parse(apiUrl),
				headers: {
				'Content-Type': 'application/json',
				},
				body: jsonEncode({
					'id': id,
					'season': season,
					'episode': episode,
					'movie': movie
				}),
			);

			if (response.statusCode == 201) {
				final data = json.decode(response.body);
				return data['path'] as String?;
			} else {
				print('Erreur lors de la recherche du contenu : ${response.body}');
				return null;
			}
		} catch (e) {
		print('Erreur lors de la requête : $e');
		return null;
		}
	}

	///////////////////////////////////////////////////////////////
	/// retourne une liste de saisons  au moins partiellement dl
	bool checkDlSeason(Map<String, dynamic> season) {
		if (season['complete']) {
			return true;
		} else {
			List<dynamic> eps = season['episode'];
			if (eps.length > 1) {
				return true;
			} else {
				if (eps.length == 1 && eps.first != -1) {
					return true;
				}
			}
			return false;
		}
	}
}