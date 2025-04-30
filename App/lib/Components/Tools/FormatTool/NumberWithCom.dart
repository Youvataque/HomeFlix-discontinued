String numberWithCom(int nb) {
	String result = "";
	int nbcom = 0;
	if (nb == 0) {
		return "Budget inconnu";
	}
	while (nb != 0) {
		if ((result.length - nbcom) % 3 == 0 && result.isNotEmpty) {
			result += " ";
			nbcom += 1;
		}
		result += (nb % 10).toString();
		nb = nb ~/ 10;
	}
	return "${result.split('').reversed.join()} \$";
} 