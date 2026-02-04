import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Colors;
import 'package:provider/provider.dart';
import 'package:ultimate_player/providers/audio_provider.dart';
import 'package:ultimate_player/screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => PlayerScreen(
                    song: song, 
                    playlist: audioProvider.queue,
                    isFromMiniPlayer: true,
                ),
              ),
            );
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.darkColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Art
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: CupertinoColors.systemGrey,
                    // TODO: Image.file for local art
                  ),
                  child: const Icon(CupertinoIcons.music_note_2, color: CupertinoColors.white),
                ),
                
                // Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600), // Keep white for contrast on dark miniplayer
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: const TextStyle(color: CupertinoColors.systemGrey3, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Controls
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: audioProvider.togglePlayPause,
                  child: Icon(
                    audioProvider.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: audioProvider.skipToNext,
                  child: const Icon(CupertinoIcons.forward_fill, color: CupertinoColors.white),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
