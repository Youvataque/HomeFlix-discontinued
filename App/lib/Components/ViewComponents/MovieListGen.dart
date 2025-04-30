import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';

///////////////////////////////////////////////////////////////
/// composant générant une listView de films
class MovieListGen extends StatefulWidget {
	final List<Widget> imgList;
	final List<Map<String, dynamic>> datas;
	final bool movie;
	final String leftWord;
	final double imgWidth;
	const MovieListGen({
		super.key,
		required this.imgList,
		required this.datas,
		required this.movie,
		required this.leftWord,
		required this.imgWidth
	});

	@override
	State<MovieListGen> createState() => _MovieListGenState();
}

class _MovieListGenState extends State<MovieListGen> {
	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: SizedBox(
				width: MediaQuery.sizeOf(context).width,
				height: widget.imgWidth * 1.5,
				child: ListView.separated(
					separatorBuilder:(context, index) => const Gap(10),
					scrollDirection: Axis.horizontal,
					itemCount: 20,
					itemBuilder: (context, index) => ClipRRect(
						borderRadius: BorderRadius.circular(7.5),
						child: imgButton(widget.imgList[index], widget.datas[index]),
					),
				),
			),
		);
	}

  ///////////////////////////////////////////////////////////////
  /// Ui du bouton image 
	Widget imgButton(Widget img, Map<String, dynamic> selectData) {
		return SizedBox(
			height: double.infinity,
			child: ElevatedButton(
				style: ElevatedButton.styleFrom(
					padding: EdgeInsets.zero,
					backgroundColor: Colors.transparent,
					surfaceTintColor: Colors.transparent,
					disabledBackgroundColor: Colors.transparent
				),
				onPressed: () => toContentView(context, selectData, img, widget.movie, widget.leftWord),
				child: img,
			),
		);
	}
}