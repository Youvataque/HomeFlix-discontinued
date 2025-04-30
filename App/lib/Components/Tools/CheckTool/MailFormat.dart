///////////////////////////////////////////////////////////////
/// Vérifie que l'email est correctement formatté
bool isEmailFormat(String email) {
  final emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    caseSensitive: false,
    multiLine: false,
  );
  return emailRegex.hasMatch(email);
}

///////////////////////////////////////////////////////////////
/// convertit un texte vers sa version la plus basique pour des comparaisons souples !
String toBasics(String word) {
  String basifiedWord = word;
  basifiedWord = retirerAccents(basifiedWord);
  basifiedWord = retirerMaj(basifiedWord);
  basifiedWord = retirerEspTiret(basifiedWord);
  return basifiedWord;
}

  ///////////////////////////////////////////////////////////////
  /// Supprime tout les accents d'une chaine de caracère
  String retirerAccents(String texteAvecAccents) {
    final Map<String, String> accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ñ': 'n',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y',
      'ÿ': 'y'
    };

    String texteSansAccents = '';
    for (int i = 0; i < texteAvecAccents.length; i++) {
      final char = texteAvecAccents[i];
      texteSansAccents += accents[char] ?? char;
    }
    return texteSansAccents;
  }

  ///////////////////////////////////////////////////////////////
  /// Supprime toutes les majuscules d'une chaine de caractère
  String retirerMaj(String texteAvecMaj) {
    return texteAvecMaj.toLowerCase();
  }

  ///////////////////////////////////////////////////////////////
  /// Supprime tout les espaces d'une chaine de caractère
  String retirerEspTiret(String texteAvecEsp) {
    String texteSans = '';
    for (int i = 0; i < texteAvecEsp.length; i++) {
      if (texteAvecEsp[i] != " " && texteAvecEsp[i] != "-" && texteAvecEsp[i] != "_") {
        texteSans += texteAvecEsp[i];
      }
    }
    return texteSans;
  }