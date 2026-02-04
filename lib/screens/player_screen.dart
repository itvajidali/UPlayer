import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; 
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:ultimate_player/models/song.dart';
import 'package:ultimate_player/providers/audio_provider.dart';
import 'dart:ui';

class PlayerScreen extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final bool isFromMiniPlayer;

  const PlayerScreen({
      super.key, 
      required this.song, 
      required this.playlist,
      this.isFromMiniPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentSong = audioProvider.currentSong ?? song;

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemBackground,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.systemBackground.withOpacity(0.5),
            middle: Text(
              "Now Playing",
              style: TextStyle(color: CupertinoColors.label.withOpacity(0.8)),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.label),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          child: Stack(
            children: [
              // Blurred Background
              Positioned.fill(
                child: Container(color: CupertinoColors.systemBackground) // Fallback
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: CupertinoColors.systemBackground.withOpacity(0.5),
                  ),
                ),
              ),
              
              // Content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Art Placeholder
                    Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: CupertinoColors.label.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(CupertinoIcons.music_note, size: 100, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 50),
                    
                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            currentSong.title,
                            style: const TextStyle(
                              color: CupertinoColors.label,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentSong.artist,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: StreamBuilder<Duration>(
                          stream: audioProvider.audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final total = audioProvider.audioPlayer.duration ?? Duration.zero;
                            return ProgressBar(
                              progress: position,
                              total: total,
                              onSeek: (duration) {
                                audioProvider.audioPlayer.seek(duration);
                              },
                              baseBarColor: CupertinoColors.systemGrey.withOpacity(0.3),
                              progressBarColor: CupertinoColors.label,
                              thumbColor: CupertinoColors.label,
                              thumbRadius: 8,
                              timeLabelTextStyle: TextStyle(
                                color: CupertinoColors.label.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }),
                    ),

                    const SizedBox(height: 40),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          onPressed: audioProvider.skipToPrevious,
                          child: const Icon(CupertinoIcons.backward_fill, color: CupertinoColors.label, size: 40),
                        ),
                        const SizedBox(width: 20),
                        CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: audioProvider.togglePlayPause,
                            child: Icon(
                                audioProvider.isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                                color: CupertinoColors.label, 
                                size: 80
                            ),
                        ),
                        const SizedBox(width: 20),
                        CupertinoButton(
                          onPressed: audioProvider.skipToNext,
                          child: const Icon(CupertinoIcons.forward_fill, color: CupertinoColors.label, size: 40),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
