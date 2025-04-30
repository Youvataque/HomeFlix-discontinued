import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/FondamentalAppCompo/SecondTop.dart';
import 'package:homeflix/Components/ViewComponents/MovieListGen.dart';
import 'package:homeflix/Components/ViewComponents/MovieListGen2.dart';
import 'package:homeflix/Components/ViewComponents/SecondTitle.dart';
import 'package:homeflix/Data/TmdbServices.dart';

class Categview extends StatefulWidget {
	final Map<String, dynamic> details;
	final List<Map<String, dynamic>> favData;
	final List<Map<String, dynamic>> allData;
	final String leftWord;
	final bool movie;
	const Categview({
		super.key,
		required this.details,
		required this.favData,
		required this.allData,
		required this.leftWord,
		required this.movie
	});

  @override
  State<Categview> createState() => _CategviewState();
}

class _CategviewState extends State<Categview> {
	List<Map<String, dynamic>> newData = [];
	List<Map<String, dynamic>> favData = [];
	final ScrollController _scrollController = ScrollController();
	bool _isLoading = false;
	@override
	void initState() {
		super.initState();
		newData = widget.allData;
		_scrollController.addListener(_onScroll);
	}

	@override
	void dispose() {
		_scrollController.removeListener(_onScroll);
		_scrollController.dispose();
		super.dispose();
	}

	void _onScroll() {
		if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
		_loadMoreData();
		}
	}

	Future<void> _loadMoreData() async {
		setState(() {
			_isLoading = true;
		});

		final data = await TMDBService().addMore(
			'https://api.themoviedb.org/3/discover/${widget.movie ? 'movie' : 'tv'}?api_key=${dotenv.get('TMDB_KEY')}&with_genres=${widget.details['id']}&include_adult=false&include_null_first_air_dates=false&language=fr-FR&sort_by=first_air_date.desc&vote_count.gte=100',
			newData
		);

		setState(() {
			newData = List.from(newData)..addAll(data);
			_isLoading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		newData = widget.allData;
		favData = widget.favData;
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: Stack(
				children: [
					SingleChildScrollView(
						controller: _scrollController,
						child: Column(
							children: [
								const Gap(105),
								const Secondtitle(title: "Les plus aimés"),
								const Gap(10),
								MovieListGen(
									imgList: List.generate(favData.length, (x) {
										final posterPath = favData[x]['poster_path'];
										if (posterPath == null) {
											return const SizedBox.shrink();
										}
										return TMDBService().createImg(
											widget.favData[x]['id'].toString(),
											(MediaQuery.sizeOf(context).width - 30) / 2,
											widget.movie,
											2 / 3,
											false,
											"500"
										);
									}),
									datas: favData,
									movie: widget.movie,
									leftWord: widget.details['name'],
									imgWidth: (MediaQuery.sizeOf(context).width - 30) / 2,
								),
								const Gap(35),
								const Secondtitle(title: "Ce que nous avons"),
								const Gap(10),
								MovieListGen2(
									imgList: List.generate(newData.length, (x) {
										final posterPath = newData[x]['poster_path'];
										if (posterPath == null) {
											return const SizedBox.shrink();
										}
										return TMDBService().createImg(
											newData[x]['id'].toString(),
											(MediaQuery.sizeOf(context).width - 30) / 2,
											widget.movie,
											2 / 3,
											false,
											"500"
										);
									}),
									datas: newData,
									movie: widget.movie,
									leftWord: widget.details['name'],
									imgWidth: (MediaQuery.sizeOf(context).width - 30) / 2,
									isLoading: _isLoading,
								),
								const Gap(50)
							],
						),
					),
					Secondtop(
						title: widget.details['name'],
						leftWord: widget.leftWord,
						color: Theme.of(context).primaryColor.withOpacity(0.5),
						func: () async {
							final fetchedFavData = await TMDBService().fetchContent(
								20, 
								'https://api.themoviedb.org/3/discover/${widget.movie ? 'movie' : 'tv'}?api_key=${dotenv.get('TMDB_KEY')}&with_genres=${widget.details['id']}&vote_count.gte=100&sort_by=vote_average.desc&language=fr-FR', 
								-1
							);
							final fetchedNewData = await TMDBService().fetchContent(
								20, 
								'https://api.themoviedb.org/3/discover/${widget.movie ? 'movie' : 'tv'}?api_key=${dotenv.get('TMDB_KEY')}&with_genres=${widget.details['id']}&include_adult=false&include_null_first_air_dates=false&language=fr-FR&page=1&sort_by=first_air_date.desc&vote_count.gte=100', 
								1
							);
							setState(() {
								favData = fetchedFavData;
								newData = fetchedNewData;
							});
						},
					),
				],
			)
		);
	}
}