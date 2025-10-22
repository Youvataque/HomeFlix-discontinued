import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:homeflix/Data/TmdbServices.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
    Future<String?>? _imageUrlFuture;

    @override
    void initState() {
        super.initState();
        _imageUrlFuture = TMDBService().getImgUrlWithoutPath(
            widget.movieId,
            widget.movie,
            widget.mode,
            widget.quality,
        );
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<String?>(
            future: _imageUrlFuture,
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                        return const Text('Erreur de téléchargement de l\'image');
                    } else if (snapshot.hasData && snapshot.data != null) {
                        return SizedBox(
                            width: widget.width,
                            child: AspectRatio(
                                aspectRatio: widget.aspectRatio,
                                child: CachedNetworkImage(
                                    imageUrl: snapshot.data!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => CupertinoActivityIndicator(
                                        radius: 10,
                                        color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    errorWidget: (context, url, error) => const Text('Erreur de téléchargement'),
                                ),
                            ),
                        );
                    } else {
                        return const Text('Image non disponible');
                    }
                } else {
                    return CupertinoActivityIndicator(
                        radius: 10,
                        color: Theme.of(context).colorScheme.secondary,
                    );
                }
            },
        );
    }
}