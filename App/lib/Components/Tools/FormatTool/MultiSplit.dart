List<String> multiSplit(String word, String separators) {
	List<String> result = [word];
	List<String> resultTemp = [];
	for (int x = 0; x < separators.length; x++) {
		for (int y = 0; y < result.length; y++) {
			resultTemp.addAll(result[y].split(separators[x]));
		}
		result.clear();
		for (var item in resultTemp) {
			if (item.isNotEmpty) {
				result.add(item);
			}
		}
		resultTemp.clear();
	}
	return result;
}