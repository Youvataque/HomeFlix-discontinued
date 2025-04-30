import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/CategoriGen.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';
import 'package:homeflix/Components/ViewComponents/MovieListGen.dart';
import 'package:homeflix/Components/ViewComponents/OpenCarouselSelec.dart';
import 'package:homeflix/Components/ViewComponents/SecondTitle.dart';
import 'package:homeflix/Data/TmdbServices.dart';

class Films extends StatefulWidget {
	const Films({super.key});

	@override
	State<Films> createState() => _FilmsState();
}

///////////////////////////////////////////////////////////////
/// corp du code
class _FilmsState extends State<Films> {
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
				TMDBService.the10movieTren[x]['id'].toString(),
				MediaQuery.of(context).size.width,
				true,
				2 / 3,
				false,
				"1280"
			));
		}
		for (int x = 0; x < 20; x++) {
			img20.add(TMDBService().createImg(
				TMDBService.the20moviePop[x]['id'].toString(),
				150,
				true,
				2 / 3,
				false,
				"500"
			));
			recentImg20.add(TMDBService().createImg(
				TMDBService.the20movieRecent[x]['id'].toString(),
				150,
				true,
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
					datas: TMDBService.the20moviePop,
					movie: true,
					leftWord: "Films",
					imgWidth: 150,
				),
				const Gap(35),
				const Secondtitle(title: "Sorties cette année"),
				const Gap(10),
				MovieListGen(
					imgList: recentImg20,
					datas: TMDBService.the20movieRecent,
					movie: true,
					leftWord: "Films",
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
							func: (index) => toCategView(context, TMDBService.movieCateg[index], "Films", true),
							data: TMDBService.movieCateg,
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
			width: MediaQuery.sizeOf(context).width,
			height: MediaQuery.sizeOf(context).width * 1.5 + 22,
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
			func: () => toContentView(context, TMDBService.the10movieTren[current10], img10[current10], true, "Films")
		);
	}
}