import 'package:flutter/material.dart';
import 'package:homeflix/Components/FondamentalAppCompo/Settings.dart';
import 'package:homeflix/Components/FondamentalAppCompo/TopOfView.dart';
import 'package:homeflix/Components/ViewComponents/SearchPage.dart';

//Pages
import 'package:homeflix/Films.dart';
import 'package:homeflix/MyDataPages/MyData.dart';
import 'package:homeflix/Series.dart';

///////////////////////////////////////////////////////////////
/// Appbar de l'application
class MyTabbar extends StatefulWidget {
	const MyTabbar({
		super.key,
	});

	@override
	State<MyTabbar> createState() => _MyTabbarState();
}

///////////////////////////////////////////////////////////////
/// Code principale
class _MyTabbarState extends State<MyTabbar> {
	int selectedIndex = 0;
	List<Widget> pagesBody = [];
	List<String> pagesTitle = [
		"Les films",
		"Les séries",
		"Votre serveur",
	];

	///////////////////////////////////////////////////////////////
	/// corp du code
	@override
	Widget build(BuildContext context) {
		pagesBody = [
			pageHeader(const Films(), false),
			pageHeader(const Series(), false),
			pageHeader(const MyData(), false),
		];

		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: IndexedStack(
				index: selectedIndex,
				children: pagesBody,
			),
			bottomNavigationBar: ClipRRect(
				child: BottomNavigationBar(
					elevation: 0,
					type: BottomNavigationBarType.fixed,
					backgroundColor: Theme.of(context).primaryColor,
					items: <BottomNavigationBarItem> [
						item('Films', Icons.local_movies, Icons.local_movies),
						item('Series', Icons.movie, Icons.movie),
						item('Serveur', Icons.storage, Icons.storage_outlined),
					],
					fixedColor: Theme.of(context).colorScheme.tertiary,
					unselectedItemColor: Theme.of(context).textTheme.labelLarge!.color,
					selectedLabelStyle: const TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w600
					),
					unselectedLabelStyle: const TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w600
					),
					currentIndex: selectedIndex,
					onTap: onTapped,
				),
			),
		);
  	}

	///////////////////////////////////////////////////////////////
	/// Dessine un élément de tabbar
  	BottomNavigationBarItem item(String title, IconData fill, IconData unFill) {
		return BottomNavigationBarItem(
			backgroundColor: Theme.of(context).colorScheme.secondary,
			icon: Icon(
				unFill,
				color: Theme.of(context).textTheme.labelLarge!.color
			),
			activeIcon: Icon(
				fill,
				color: Theme.of(context).colorScheme.tertiary
			),
			label: title
		);
  	}

	///////////////////////////////////////////////////////////////
	/// format du haut de page
  	Stack pageHeader(Widget myPage, bool isAdd) {
		return Stack(
			children: [
				SingleChildScrollView(
					child: Column(
						children: [
							myPage
						],
					)
				),
				TopOfView(
					goSettings: () {
						Navigator.push(
							context,
							MaterialPageRoute(builder: (context) => const Settings(leftWord: "Accueil")),
						);
					},
					search: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Searchpage()))
				),
			],
		);
  	}

	///////////////////////////////////////////////////////////////
	/// change l'index en fonction de celui tapé
	void onTapped(int index) {
		setState(() {
			selectedIndex = index;
		});
	}
}
