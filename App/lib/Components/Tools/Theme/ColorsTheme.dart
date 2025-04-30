import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
	brightness: Brightness.light,
	splashColor:  Colors.transparent,
	focusColor: const Color.fromRGBO(238, 238, 238, 1),
	primaryColor: const Color.fromRGBO(34, 40, 47, 1),
	colorScheme: const ColorScheme.light(
		secondary: Color.fromRGBO(238, 238, 238, 1),
		tertiary: Color.fromRGBO(16, 223, 168, 1)
	),
	textSelectionTheme: const TextSelectionThemeData(
		cursorColor: Color.fromARGB(255, 89, 157, 230),
		selectionColor: Color.fromARGB(255, 89, 157, 230),
		selectionHandleColor: Color.fromARGB(255, 89, 157, 230),
	),
	textTheme: const TextTheme(
		labelLarge: TextStyle(
			color: Color.fromRGBO(180, 180, 180, 1),
		)
	),
	scaffoldBackgroundColor: const Color.fromRGBO(20, 24, 29, 1),
	dividerColor: const Color.fromARGB(255, 68, 67, 67),
	shadowColor: Colors.black45
);
