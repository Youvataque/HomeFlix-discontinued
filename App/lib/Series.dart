import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/CategoriGen.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Components/ViewComponents/MovieListGen.dart';
import 'package:homeflix/Components/ViewComponents/OpenCarouselSelec.dart';
import 'package:homeflix/Components/ViewComponents/SecondTitle.dart';
import 'package:homeflix/Data/TmdbServices.dart';

class Series extends StatefulWidget {
	const Series({super.key});

	@override
	State<Series> createState() => _SeriesState();
}

class _SeriesState extends State<Series> {
	List<Widget> img10 = [];
	List<Widget> img20 = [];
	List<Widget> recentImg20 = [];
	List<Widget> trashImg20 = [];
	int current10 = 0;

	///////////////////////////////////////////////////////////////
	/// Ajoute les images à une liste d'image
	void addImg() {
		for (int x = 0; x < 10; x++) {
			img10.add(TMDBService().createImg(
				TMDBService.the10serieTren[x]['id'].toString(),
				MediaQuery.of(context).size.width,
				false,
				2 / 3,
				false,
				"1280"
			));
		}
		for (int x = 0; x < 20; x++) {
			img20.add(TMDBService().createImg(
				TMDBService.the20seriePop[x]['id'].toString(),
				150,
				false,
				2 / 3,
				false,
				"500"
			));
			recentImg20.add(TMDBService().createImg(
				TMDBService.the20serieTop[x]['id'].toString(),
				150, 
				false,
				2 / 3,
				false,
				"500"
			));
		}
	}

	@override
	Widget build(BuildContext context) {
		addImg();
		return Column(
			children: [
				trendZone(),
				const Gap(35),
				const Secondtitle(title: "Populaires"),
				const Gap(10),
				MovieListGen(
					imgList: img20,
					datas: TMDBService.the20seriePop,
					movie: false,
					leftWord: "Séries",
					imgWidth: 150,
				),
				const Gap(35),
				const Secondtitle(title: "Les mieux notés"),
				const Gap(10),
				MovieListGen(
					imgList: recentImg20,
					datas: TMDBService.the20serieTop,
					movie: false,
					leftWord: "Séries",
					imgWidth: 150,
				),
				const Gap(35),
				const Secondtitle(title: "Genres"),
				const Gap(10),
				SizedBox(
					width: MediaQuery.sizeOf(context).width,
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 10),
						child: Categorigen(
							func: (index) => toCategView(context, TMDBService.serieCateg[index], "Series", false),
							data: TMDBService.serieCateg,
						)
					),
				),
				const Gap(20)
			]
		);
	}

	///////////////////////////////////////////////////////////////
	/// zone des films du moment
	Widget trendZone() {
		return SizedBox(
			height: MediaQuery.sizeOf(context).width * 1.5 + 22,
			width: MediaQuery.sizeOf(context).width,
			child: Stack(
				children: [
					CarouselSlider(
						items: img10,
						options: CarouselOptions(
							viewportFraction: 1,
							autoPlay: true,
							aspectRatio: 2 / 3,
							onPageChanged: (index, reason) => current10 = index, 
						),
					),
					openOnOf7()
				],
			),
		);
	}

	///////////////////////////////////////////////////////////////
	/// Bouton ouvrant l'un des 10 trend
	Widget openOnOf7() {
		return Opencarouselselec(
			func: () {
				toContentView(context, TMDBService.the10serieTren[current10], img10[current10], false, "Séries");
			},
		);
	}
}