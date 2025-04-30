String cleanString(String word) {
  return word.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}