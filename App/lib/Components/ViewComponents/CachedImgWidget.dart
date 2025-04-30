import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:homeflix/Data/TmdbServices.dart';

///////////////////////////////////////////////////////////////
/// Mes en forme les images téléchargés par TDMBServices
class CachedImageWidget extends StatefulWidget {
	final String movieId;
	final double width;
	final bool movie;
	final double aspectRatio;
	final bool mode;
	final String quality;

	const CachedImageWidget({
		super.key,
		required this.movieId,
		required this.width,
		required this.movie,
		required this.aspectRatio,
		required this.mode,
		required this.quality,
	});

	@override
	_CachedImageWidgetState createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
	Future<File?>? _imageFuture;

	@override
	void initState() {
		super.initState();
		_imageFuture = TMDBService().getImgWithoutPath(
			widget.movieId,
			widget.movie,
			widget.mode,
			widget.quality,
		);
  	}

	@override
	Widget build(BuildContext context) {
		return FutureBuilder<File?>(
			future: _imageFuture,
			builder: (context, snapshot) {
				if (snapshot.connectionState == ConnectionState.done) {
					if (snapshot.hasError) {
						return const Text('Erreur de téléchargement de l\'image');
					} else if (snapshot.hasData && snapshot.data != null) {
						final file = snapshot.data!;
						return SizedBox(
							width: widget.width,
							child: AspectRatio(
								aspectRatio: widget.aspectRatio,
								child: Image.file(file, fit: BoxFit.cover),
							),
						);
					} else {
						return SizedBox(
							width: widget.width,
							child: AspectRatio(
								aspectRatio: widget.aspectRatio,
								child: Text(
									"Image non disponible ${widget.movieId}",
									style: const TextStyle(color: Colors.white),
								),
							),
						);
					}
				} else {
					return Container(
						width: widget.width,
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(10),
							color: Theme.of(context).primaryColor,
						),
						child: AspectRatio(
							aspectRatio: widget.aspectRatio,
							child: CupertinoActivityIndicator(
								radius: 10,
								color: Theme.of(context).colorScheme.secondary,
							),
						),
					);
				}
			},
		);
	}
}