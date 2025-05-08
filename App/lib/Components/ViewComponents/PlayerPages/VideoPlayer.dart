import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter/material.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/PlayerOverlay.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoProxyServer.dart';

class VlcVideoPlayer extends StatefulWidget {
	final String videoUrl;
	final VideoProxyServer videoProxy;

	const VlcVideoPlayer({
		super.key,
		required this.videoUrl,
		required this.videoProxy
	});

	@override
	_VlcVideoPlayerState createState() => _VlcVideoPlayerState();
}

class _VlcVideoPlayerState extends State<VlcVideoPlayer> {
	late VlcPlayerController _vlcPlayerController;
	double scale = 1.0;
	bool _show = false;
	bool _isInitialized = false;
	Map<int, String> _audioTracks = {};
	Map<int, String> _subtitleTracks = {};

	@override
	void initState() {
		super.initState();
		_initializePlayer();
		SystemChrome.setPreferredOrientations([
			DeviceOrientation.landscapeLeft,
			DeviceOrientation.landscapeRight,
		]);
    closeIfError();
	}

  void  closeIfError() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_vlcPlayerController.value.isPlaying && mounted) {
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

	void _initializePlayer() {
		_vlcPlayerController = VlcPlayerController.network(
			widget.videoUrl,
			hwAcc: HwAcc.full,
			autoPlay: true,
			options: VlcPlayerOptions(
				advanced: VlcAdvancedOptions([
					'--fullscreen',
					'--video-on-top',
					'--no-video-title-show',
					'--crop=16:9',
					'--scale=1.2',
					'--align=0',
				]),
			),
		);

		_vlcPlayerController.addListener(() {
			if (_vlcPlayerController.value.isInitialized && !_isInitialized) {
				setState(() {
					_isInitialized = true;
				});
				Future.delayed(const Duration(seconds: 2), () {
					_fetchTracks();
				});
			}
		});
	}

	void _fetchTracks() async {
		try {
			final audioTracks = await _vlcPlayerController.getAudioTracks();
			final subtitleTracks = await _vlcPlayerController.getSpuTracks();
			setState(() {
				_audioTracks = audioTracks;
				_subtitleTracks = subtitleTracks;
			});
		} catch (e) {
			print('Erreur lors de la récupération des pistes: $e');
		}
	}

	@override
	void dispose() {
		_vlcPlayerController.stop();
		_vlcPlayerController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return body();
	}

	Widget body() {
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
								child: player(),
							),
						),
						SizedBox(
							width: MediaQuery.of(context).size.width,
							height: MediaQuery.of(context).size.height,
							child: GestureDetector(
									onTap: () {
										setState(() {
											_show = !_show;
										});
									}
								),
							),
						PlayerOverlay(
							show: _show,
							controller: _vlcPlayerController,
							videoProxy: widget.videoProxy,
							audioTracks: _audioTracks,
							subtitleTracks: _subtitleTracks,
							updateScale: (value) => setState(() {
							  scale = value;
							})
						),
					],
				),
			),
		);
	}

	Widget player() {
		return VlcPlayer(
			controller: _vlcPlayerController,
			aspectRatio: 16 / 9,
			placeholder: const Center(
				child: CircularProgressIndicator(),
			),
		);
	}
}