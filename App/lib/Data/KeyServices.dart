import 'package:shared_preferences/shared_preferences.dart';

///////////////////////////////////////////////////////////////
/// Gestionnaire de clef
class Keyservices {
	static String nightcenterIp = "";
	static String nightcenterKey = "";
	static String nightcenterPort = "";
	///////////////////////////////////////////////////////////////
	/// permet de modifier les clef enregistrés en mémoire.
	Future<void> save(String newIp, String newKey, String newPort) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setString("keyIp", newIp);
		await prefs.setString("keyKey", newKey);
		await prefs.setString("keyPort", newPort);
	}

	///////////////////////////////////////////////////////////////
	/// Permet de charger en mémoire les clefs enregistré dans le cache
	Future<void> load() async {
		final prefs = await SharedPreferences.getInstance();
		nightcenterIp = prefs.getString("keyIp") ?? '';
		nightcenterKey = prefs.getString("keyKey") ?? '';
		nightcenterPort = prefs.getString("keyPort") ?? '';
	}
}	