import 'package:flutter/material.dart';

class InfoText extends StatelessWidget {
  final String text;
  const InfoText({
    super.key,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 17,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}