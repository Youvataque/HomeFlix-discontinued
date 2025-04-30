import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Tools/FormatTool/MinToHour.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Data/TmdbServices.dart';

///////////////////////////////////////////////////////////////
/// template pour les épisodes de séries
class Eptemplate extends StatefulWidget {
	final int index;
	final int time;
	final String title;
	final String imgPath;
	final String id;
	final String overview;
	final VoidCallback onTap;
	const Eptemplate({
		super.key,
		required this.index,
		required this.time,
		required this.title,
		required this.imgPath,
		required this.id,
		required this.overview,
		required this.onTap
	});

	@override
	State<Eptemplate> createState() => _EptemplateState();
}

class _EptemplateState extends State<Eptemplate> {

	///////////////////////////////////////////////////////////////
	/// corp du code de la page
	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: MediaQuery.sizeOf(context).width - 16,
			child: Column(
				children: [
					topPart(),
					const Gap(10),
					overviPart(),
				],
			),
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des composants
 
    ///////////////////////////////////////////////////////////////
	/// partie supèrieur contant img, titre et durée
	Row topPart() {
		return Row(
			mainAxisAlignment: MainAxisAlignment.start,
			children: [
				playButton(),
				const Gap(10),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								"${(widget.index + 1).toString()}. ${widget.title}",
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(
									color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
									fontSize: 15,
									fontWeight: FontWeight.w600
								),
							),
							Text(
								minToHour(widget.time),
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(
									color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
									fontSize: 12,
									fontWeight: FontWeight.w400
								),
							),
						],
					),
				)
			],
		);
	}

	///////////////////////////////////////////////////////////////
	/// partie contenant le résumé
	Text overviPart() {
		return Text(
			widget.overview,
			maxLines: 4,
			overflow: TextOverflow.ellipsis,
			style: TextStyle(
				color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
				fontSize: 13,
				fontWeight: FontWeight.w500
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// création de l'image de l'épisode
	Widget createEpImg() {
		return FutureBuilder<File?>(
			future: TMDBService().getImgWithPath(widget.imgPath, widget.id),
			builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
				if (snapshot.connectionState == ConnectionState.waiting) {
					return myIndicator(context, 10);
				} else if (snapshot.hasError) {
					return const Center(
						child: Text(
						'Erreur de chargement de l\'image',
						style: TextStyle(color: Colors.red),
						),
					);
				} else if (snapshot.hasData && snapshot.data != null) {
					final file = snapshot.data!;
					return ClipRRect(
						borderRadius: BorderRadius.circular(10),
						child: Image.file(
							file,
							width: MediaQuery.sizeOf(context).width / 3,
							fit: BoxFit.cover,
						),
					);
				} else {
					return const Center(
						child: Text(
						'Image non disponible',
						style: TextStyle(color: Colors.grey),
						),
					);
				}
			},
		);
	}

	///////////////////////////////////////////////////////////////
	/// bouton pour lancer la lecture
	ElevatedButton playButton() {
		return ElevatedButton(
			onPressed: () => widget.onTap(),
			style: ElevatedButton.styleFrom(
				backgroundColor: Colors.transparent,
				shadowColor: Colors.transparent,
				padding: const EdgeInsets.all(0),
				foregroundColor: Theme.of(context).colorScheme.secondary,
			),
			child: SizedBox(
				width: MediaQuery.sizeOf(context).width / 3,
				height: (MediaQuery.sizeOf(context).width / 3) * 9 / 16,
				child: Stack(
					children: [
						createEpImg(),
						Align(
							alignment: Alignment.center,
							child: Icon(
								Icons.play_circle_fill,
								size: 50,
								color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
							),
						),
					],
				),
			)
		);
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////// zone des fonctions


}