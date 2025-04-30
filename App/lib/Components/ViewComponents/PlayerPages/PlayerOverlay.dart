import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:gap/gap.dart';
import 'package:homeflix/Components/Tools/FormatTool/MinToHour.dart';

class PlayerOverlay extends StatefulWidget {
	final bool show;
	final VlcPlayerController controller;
	final Map<int, String> audioTracks;
	final Map<int, String> subtitleTracks;
	final Function(double) updateScale;

	const PlayerOverlay({
		super.key,
		required this.show,
		required this.controller,
		required this.audioTracks,
		required this.subtitleTracks,
		required this.updateScale,
	});

	@override
	State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
	bool isPlaying = true;
	double volume = 1;
	Duration currentPosition = Duration.zero;
	Duration totalDuration = Duration.zero;
	int selectedAudioTrack = 0;
	int selectedSubtitleTrack = -1;
	double scaleValue = 1.0;

	@override
	void initState() {
		super.initState();
		SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
		SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
			statusBarColor: Colors.black,
			systemNavigationBarColor: Colors.black,
		));
		_initializeListener();
	}

	void _initializeListener() {
		widget.controller.addListener(() {
			setState(() {
				isPlaying = widget.controller.value.isPlaying;
				currentPosition = widget.controller.value.position;
				totalDuration = widget.controller.value.duration;
				selectedSubtitleTrack = widget.controller.value.activeSpuTrack;
				selectedAudioTrack = widget.controller.value.activeAudioTrack;
			});
		});
	}

	void _togglePlayPause() async {
		if (isPlaying) {
			await widget.controller.pause();
		} else {
			await widget.controller.play();
		}
	}

	void _changeVolume(double newVolume) {
		setState(() {
			volume = newVolume;
			widget.controller.setVolume((volume * 100).toInt());
		});
	}

	void _seek(bool forward) {
		final newPosition = forward
				? currentPosition + const Duration(seconds: 10)
				: currentPosition - const Duration(seconds: 10);
		widget.controller.seekTo(newPosition);
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
						icon: const Icon(Icons.close, color: Colors.white),
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
						icon: const Icon(Icons.remove, color: Colors.white),
						onPressed: () => _adjustScale(-0.1),
					),
					const Text(
						"Zoom",
						style: const TextStyle(color: Colors.white, fontSize: 16),
					),
					IconButton(
						icon: const Icon(Icons.add, color: Colors.white),
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
					const Icon(Icons.volume_up, color: Colors.white),
					Slider(
						value: volume,
						min: 0.0,
						max: 1.0,
						onChanged: _changeVolume,
						activeColor: Colors.white,
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
						value: currentPosition.inSeconds.toDouble(),
						min: 0,
						max: totalDuration.inSeconds.toDouble(),
						onChanged: (value) {
							widget.controller.seekTo(Duration(seconds: value.toInt()));
						},
						activeColor: Theme.of(context).colorScheme.tertiary,
						inactiveColor: Colors.white,
					),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								_formatDuration(currentPosition),
								style: const TextStyle(color: Colors.white),
							),
							Text(
								_formatDuration(totalDuration - currentPosition),
								style: const TextStyle(color: Colors.white),
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
						icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
						onPressed: () => _seek(false),
					),
					const Gap(20),
					GestureDetector(
						onTap: _togglePlayPause,
						child: Icon(
							isPlaying ? Icons.pause : Icons.play_arrow,
							color: Colors.white,
							size: 60,
						),
					),
					const Gap(20),
					IconButton(
						icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
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
			child: DropdownButton<int>(
				dropdownColor: Colors.black87,
				value: widget.audioTracks.containsKey(selectedAudioTrack)
						? selectedAudioTrack
						: (widget.audioTracks.isNotEmpty ? widget.audioTracks.keys.first : null),
				hint: const Text("Aucune piste audio", style: TextStyle(color: Colors.white)),
				items: widget.audioTracks.entries.map((entry) {
					return DropdownMenuItem<int>(
						value: entry.key,
						child: Text(entry.value, style: const TextStyle(color: Colors.white)),
					);
				}).toList(),
				onChanged: (value) {
					if (value != null) {
						widget.controller.setAudioTrack(value);
						setState(() {
							selectedAudioTrack = value;
						});
					}
				},
			),
		);
	}

	Widget subtitleSelector() {
		return Positioned(
			bottom: 150,
			right: 40,
			child: DropdownButton<int>(
				dropdownColor: Colors.black87,
				value: widget.subtitleTracks.containsKey(selectedSubtitleTrack)
						? selectedSubtitleTrack
						: (widget.subtitleTracks.isNotEmpty ? widget.subtitleTracks.keys.first : -1),
				hint: const Text("Aucun sous-titre", style: TextStyle(color: Colors.white)),
				items: [
					const DropdownMenuItem<int>(
						value: -1,
						child: Text("Aucun sous-titre", style: TextStyle(color: Colors.white)),
					),
					...widget.subtitleTracks.entries.map((entry) {
						return DropdownMenuItem<int>(
							value: entry.key,
							child: Text(entry.value, style: const TextStyle(color: Colors.white)),
						);
					}).toList(),
				],
				onChanged: (value) {
					if (value != null) {
						widget.controller.setSpuTrack(value);
						setState(() {
							selectedSubtitleTrack = value;
						});
					}
				},
			),
		);
	}

	String _formatDuration(Duration duration) {
		return minToHour(duration.inMinutes);
	}
}