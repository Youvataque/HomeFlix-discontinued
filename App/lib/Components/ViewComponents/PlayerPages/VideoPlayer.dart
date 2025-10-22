import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/PlayerOverlay.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoProxyServer.dart';
import 'package:homeflix/main.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VlcVideoPlayer extends StatefulWidget {
	final String videoUrl;
	final VideoProxyServer videoProxy;

	const VlcVideoPlayer({
		super.key,
		required this.videoUrl,
		required this.videoProxy,
	});

	@override
	State<VlcVideoPlayer> createState() => _VlcVideoPlayerState();
}

class _VlcVideoPlayerState extends State<VlcVideoPlayer> {
	late final player = Player();
	late final controller = VideoController(player);
	double scale = 1.0;
	bool _show = false;

	@override
	void initState() {
		super.initState();
		player.open(Media(widget.videoUrl), play: true);
		WidgetsBinding.instance.addPostFrameCallback((_) {
			isPlayerFullScreen.value = true;
		});
		SystemChrome.setPreferredOrientations([
			DeviceOrientation.landscapeLeft,
			DeviceOrientation.landscapeRight,
		]);
		closeIfError();
	}

	void closeIfError() {
		Future.delayed(const Duration(seconds: 10), () {
		if (!player.state.playing && mounted) {
			print("❌ Timeout: fermeture du lecteur");
			widget.videoProxy.stopProxy();
			SystemChrome.setPreferredOrientations([
				DeviceOrientation.portraitUp,
				DeviceOrientation.portraitDown,
			]);
			Navigator.pop(context);
		}
		});
	}

	@override
	void dispose() {
		SystemChrome.setPreferredOrientations([
			DeviceOrientation.portraitUp,
			DeviceOrientation.portraitDown,
		]);
		player.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		backgroundColor: Colors.black,
		body: Align(
			alignment: Alignment.center,
			child: Stack(
			children: [
				Transform.scale(
				scale: scale,
				child: SizedBox(
					width: MediaQuery.of(context).size.width,
					height: MediaQuery.of(context).size.height,
					child: playerWidget(),
				),
				),
				SizedBox(
				width: MediaQuery.of(context).size.width,
				height: MediaQuery.of(context).size.height,
				child: GestureDetector(onTap: () {
					setState(() {
					_show = !_show;
					});
				}),
				),
				PlayerOverlay(
					show: _show,
					player: player,
					videoProxy: widget.videoProxy,
					updateScale: (value) => setState(() {
						scale = value;
					}),
				),
			],
			),
		),
		);
	}

	Widget playerWidget() {
		return Video(
			controller: controller,
			controls: NoVideoControls,
		);
	}
}