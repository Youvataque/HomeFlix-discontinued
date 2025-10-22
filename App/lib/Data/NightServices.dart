import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NIGHTServices {
	static Map<String, dynamic> specStatus = {};
  final String port = '4000';
	Future<String?> _getIdToken() async {
        try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user == null) {
                return null;
            }
            return await user.getIdToken();

        } catch (e) {
            print("Erreur critique lors de la récupération du IdToken: $e");
            return null;
        }
    }

	///////////////////////////////////////////////////////////////
	/// méthode pour récupérer les données des contenues téléchargés sur le server
	Future<Map<String, dynamic>> fetchDataStatus() async {
		Map<String, dynamic> results = {};
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return results;
		}

		final response = await http.get(
			Uri.parse("http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/contentStatus"),
			headers: {
				'Authorization': 'Bearer $idToken',
			},
		);

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			results = data;
		} else {
			print("Erreur sur le statut -> ${response.reasonPhrase}");
		}
		return results;
	}

	///////////////////////////////////////////////////////////////
	/// méthode pour récupérer les données des contenues téléchargés sur le server
	Future<Map<String, dynamic>> fetchSpecStatus() async {
		Map<String, dynamic> results = {};
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return results;
		}

		final response = await http.get(
			Uri.parse("http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/specStatus"),
			headers: {
				'Authorization': 'Bearer $idToken',
			},
		);

		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			results = data;
		} else {
			print("Erreur sur le statut -> ${response.reasonPhrase}");
		}
		return results;
	}

	///////////////////////////////////////////////////////////////
	/// Fonction pour récupérer le contenu d'une page choisie  
	/// depuis la source (C)
	Future<List<Map<String, dynamic>>> fetchQueryTorrent(int page, String name) async {
		List<Map<String, dynamic>> results = [];
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return results;
		}

		final response = await http.get(
			Uri.parse("http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/fetchTorrentContent?page=$page&name=$name"),
			headers: {
				'Authorization': 'Bearer $idToken',
			},
			
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
		final apiUrl = 'http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/contentDl';

		try {
			final user = FirebaseAuth.instance.currentUser;
			if (user == null) {
				print('❌ Erreur: Utilisateur non authentifié.');
				return;
			}
			final token = await user.getIdToken();
			final response = await http.post(
				Uri.parse(apiUrl),
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer $token',
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
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return;
		}

		final url = Uri.parse("http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/contentStatus");
		final headers = {
			'Content-Type': 'application/json',
			'Authorization': 'Bearer $idToken',
		};
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
	/// Méthode pour supprimer un contenue
	Future<void> deleteData(Map<String, dynamic> newData) async {
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return;
		}

		final url = Uri.parse("http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/contentErase");
		final headers = {
			'Content-Type': 'application/json',
			'Authorization': 'Bearer $idToken',
		};
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
		final idToken = await _getIdToken();

		if (idToken == null) {
			print("Utilisateur non authentifié");
			return null;
		}

		final apiUrl = 'http://${dotenv.get('NIGHTCENTER_IP')}:$port/api/contentSearch';

		try {
			final response = await http.post(
				Uri.parse(apiUrl),
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer $idToken',
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