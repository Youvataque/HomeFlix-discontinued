import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Tools/FormatTool/MinToHour.dart';
import 'package:homeflix/Components/ViewComponents/PlayerPages/VideoProxyServer.dart';
import 'package:media_kit/media_kit.dart';

class PlayerOverlay extends StatefulWidget {
	final bool show;
	final Player player;
	final VideoProxyServer videoProxy;
	final Function(double) updateScale;

	const PlayerOverlay({
		super.key,
		required this.show,
		required this.player,
		required this.videoProxy,
		required this.updateScale,
	});

	@override
	State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
	late bool isPlaying = widget.player.state.playing;
	late Duration position = widget.player.state.position;
	late Duration duration = widget.player.state.duration;
	late List<AudioTrack> audioTracks = widget.player.state.tracks.audio;
	late AudioTrack activeAudioTrack = widget.player.state.track.audio;
	late List<SubtitleTrack> subtitleTracks = widget.player.state.tracks.subtitle;
	late SubtitleTrack activeSubtitleTrack = widget.player.state.track.subtitle;
	double scaleValue = 1.0;

	@override
	void initState() {
		super.initState();
		SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
		SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
			statusBarColor: Colors.black,
			systemNavigationBarColor: Colors.black,
		));
		widget.player.stream.playing.listen((event) {
			if (mounted) setState(() => isPlaying = event);
		});
		widget.player.stream.position.listen((event) {
			if (mounted) setState(() => position = event);
		});
		widget.player.stream.duration.listen((event) {
			if (mounted) setState(() => duration = event);
		});
		widget.player.stream.tracks.listen((event) {
			if (mounted) {
				setState(() {
					audioTracks = event.audio;
					subtitleTracks = event.subtitle;
				});
			}
		});
		widget.player.stream.track.listen((event) {
			if (mounted) {
				setState(() {
					activeAudioTrack = event.audio;
					activeSubtitleTrack = event.subtitle;
				});
			}
		});
	}

	void _togglePlayPause() {
		widget.player.playOrPause();
	}

	void _seek(bool forward) {
		final newPosition = forward
				? position + const Duration(seconds: 10)
				: position - const Duration(seconds: 10);
		widget.player.seek(newPosition);
	}

	void _adjustScale(double delta) {
		setState(() {
			scaleValue = (scaleValue + delta).clamp(0.5, 2.0);
		});
		widget.updateScale(scaleValue);
	}

	@override
	Widget build(BuildContext context) {
		return AnimatedOpacity(
			opacity: widget.show ? 1.0 : 0.0,
			duration: const Duration(milliseconds: 300),
			child: IgnorePointer(
				ignoring: !widget.show,
				child: Stack(
					children: [
						closeButtonAndScaleControls(),
						volumeController(),
						movieControls(),
						audioSelector(),
						subtitleSelector(),
						progressBar(),
					],
				),
			),
		);
	}

	Widget closeButtonAndScaleControls() {
		return Positioned(
			top: 20,
			left: 20,
			child: Row(
				children: [
					IconButton(
						icon: Icon(Icons.close, color: Theme.of(context).colorScheme.secondary),
						onPressed: () {
							SystemChrome.setPreferredOrientations([
								DeviceOrientation.portraitUp,
								DeviceOrientation.portraitDown,
							]);
							Navigator.pop(context);
						},
					),
					const Gap(10),
					IconButton(
						icon: Icon(Icons.remove, color: Theme.of(context).colorScheme.secondary),
						onPressed: () => _adjustScale(-0.1),
					),
					Text(
						"Zoom",
						style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16),
					),
					IconButton(
						icon: Icon(Icons.add, color: Theme.of(context).colorScheme.secondary),
						onPressed: () => _adjustScale(0.1),
					),
				],
			),
		);
	}

	Widget volumeController() {
		return Positioned(
			top: 20,
			right: 40,
			child: Row(
				children: [
					Icon(Icons.volume_up, color: Theme.of(context).colorScheme.secondary),
					Slider(
						value: widget.player.state.volume / 100,
						min: 0.0,
						max: 1.0,
						onChanged: (v) => widget.player.setVolume(v * 100),
						activeColor: Theme.of(context).colorScheme.secondary,
						inactiveColor: Colors.grey,
					),
				],
			),
		);
	}

	Widget progressBar() {
		return Positioned(
			bottom: 20,
			left: 40,
			right: 40,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Slider(
						value: position.inSeconds.toDouble(),
						min: 0,
						max: duration.inSeconds.toDouble(),
						onChanged: (value) {
							widget.player.seek(Duration(seconds: value.toInt()));
						},
						activeColor: Theme.of(context).colorScheme.tertiary,
						inactiveColor: Theme.of(context).colorScheme.secondary,
					),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								_formatDuration(position),
								style: TextStyle(color: Theme.of(context).colorScheme.secondary),
							),
							Text(
								_formatDuration(duration - position),
								style: TextStyle(color: Theme.of(context).colorScheme.secondary),
							),
						],
					),
				],
			),
		);
	}

	Widget movieControls() {
		return Align(
			alignment: Alignment.center,
			child: Row(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					IconButton(
						icon: Icon(Icons.replay_10, color: Theme.of(context).colorScheme.secondary, size: 30),
						onPressed: () => _seek(false),
					),
					const Gap(20),
					GestureDetector(
						onTap: _togglePlayPause,
						child: Icon(
							isPlaying ? Icons.pause : Icons.play_arrow,
							color: Theme.of(context).colorScheme.secondary,
							size: 60,
						),
					),
					const Gap(20),
					IconButton(
						icon: Icon(Icons.forward_10, color: Theme.of(context).colorScheme.secondary, size: 30),
						onPressed: () => _seek(true),
					),
				],
			),
		);
	}

	Widget audioSelector() {
		return Positioned(
			bottom: 100,
			right: 40,
			child: DropdownButton<String>(
				dropdownColor: Theme.of(context).primaryColor,
				value: activeAudioTrack.id,
				hint: Text(
					"Aucune piste audio",
					style: TextStyle(color: Theme.of(context).colorScheme.secondary),
				),
				items: audioTracks.map((track) {
					return DropdownMenuItem<String>(
						value: track.id,
						child: Text(
							track.title ?? track.id,
							style: TextStyle(
								color: track.id == activeAudioTrack.id
									? Theme.of(context).primaryColor
									: Theme.of(context).colorScheme.secondary,
							),
						),
					);
				}).toList(),
				onChanged: (value) {
					if (value != null) {
						final track = audioTracks.firstWhere((t) => t.id == value);
						widget.player.setAudioTrack(track);
					}
				},
			),
		);
	}

	Widget subtitleSelector() {
		return Positioned(
			bottom: 150,
			right: 40,
			child: DropdownButton<String>(
				dropdownColor: Theme.of(context).primaryColor,
				value: activeSubtitleTrack.id,
				hint: Text(
					"Aucun sous-titre",
					style: TextStyle(color: Theme.of(context).colorScheme.secondary)
				),
				items: subtitleTracks.map((track) {
					return DropdownMenuItem<String>(
						value: track.id,
						child: Text(
							track.title ?? track.id,
							style: TextStyle(
								color: track.id == activeSubtitleTrack.id
									? Theme.of(context).primaryColor
									: Theme.of(context).colorScheme.secondary,
							),
						),
					);
				}).toList(),
				onChanged: (value) {
					if (value != null) {
						final track = subtitleTracks.firstWhere((t) => t.id == value);
						widget.player.setSubtitleTrack(track);
					}
				},
			),
		);
	}

	String _formatDuration(Duration duration) {
		return minToHour(duration.inMinutes);
	}
}