String minToHour(int min) {
	if (min < 60) {
		return min.toString() + "min";
	}
	else {
		return "${min ~/ 60}h${min % 60}min";
	}
}