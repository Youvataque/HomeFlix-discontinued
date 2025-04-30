import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/ViewComponents/LitleComponent.dart';

class MovieListGen2 extends StatefulWidget {
	final List<Widget> imgList;
	final List<Map<String, dynamic>> datas;
	final bool movie;
	final String leftWord;
	final double imgWidth;
	final bool isLoading;
	const MovieListGen2({
		super.key,
		required this.imgList,
		required this.datas,
		required this.movie,
		required this.leftWord,
		required this.imgWidth,
		required this.isLoading
	});

	@override
	State<MovieListGen2> createState() => _MovieListGen2State();
}

class _MovieListGen2State extends State<MovieListGen2> {
  @override
  Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			child: ListView.separated(
				itemCount: widget.imgList.length ~/ 2,
				physics: const NeverScrollableScrollPhysics(),
				shrinkWrap: true,
				padding: EdgeInsets.zero,
				separatorBuilder: (context, index) => const Gap(20),
				itemBuilder:(context, index) => Row(
					children: [
						ClipRRect(
							borderRadius: BorderRadius.circular(7.5),
							child: SizedBox(
								height: 1.5 * widget.imgWidth,
								child: imgButton(widget.imgList[index * 2], widget.datas[index * 2]),
							),
						),
						const Gap(10),
						ClipRRect(
							borderRadius: BorderRadius.circular(7.5),
							child: SizedBox(
								height: 1.5 * widget.imgWidth,
								child: imgButton(widget.imgList[(index * 2) + 1], widget.datas[(index * 2) + 1]),
							),
						),
					],
				)
			)
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