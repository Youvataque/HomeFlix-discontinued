import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoPlayer.dart';
import 'package:homeflix/Data/KeyServices.dart';
import 'package:homeflix/Data/NightServices.dart';

///////////////////////////////////////////////////////////////
/// template des pages de film
class MoviePages extends StatefulWidget {
  final String id;
	final Map<String, dynamic> serveurData;
	final bool movie;
	const MoviePages({
		super.key,
    required this.id,
		required this.serveurData,
		required this.movie
	});

	@override
	State<MoviePages> createState() => _MoviePagesState();
}

///////////////////////////////////////////////////////////////
/// corps du code
class _MoviePagesState extends State<MoviePages> {

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: MediaQuery.sizeOf(context).width - 16,
			height: 40,
			child: ElevatedButton(
				onPressed: () async {
					final path = await NIGHTServices().searchContent(
						widget.id,
						0,
						0,
						widget.movie
					);
					if (path == null) {
						print("Path non trouvé, annulation.");
						return;
					}
					print(path);
					final decodedPath = Uri.decodeComponent(path);
					final videoUrl = "http://${Keyservices.nightcenterIp}:${Keyservices.nightcenterPort}/api/streamVideo?api_key=${Keyservices.nightcenterKey}&path=$decodedPath";
					Navigator.push(
						context,
						MaterialPageRoute(builder: (context) => VlcVideoPlayer(videoUrl: videoUrl))
					);
				},
				style: ElevatedButton.styleFrom(
						backgroundColor: Theme.of(context).colorScheme.secondary,
						foregroundColor: Theme.of(context).scaffoldBackgroundColor,
						shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(5)
						)
				),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.center,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						Icon(
							Icons.play_arrow,
							color: Theme.of(context).scaffoldBackgroundColor,
							size: 28,
						),
						const Gap(5),
						Text(
							"Lecture",
							style: TextStyle(
									fontSize: 17,
									fontWeight: FontWeight.w600,
									color: Theme.of(context).scaffoldBackgroundColor
							),
						)
					],
				)
			),
		);
	}
}