import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Icons, Colors, ListTile, Divider;
import 'package:provider/provider.dart';
import 'package:ultimate_player/models/playlist.dart';
import 'package:ultimate_player/models/song.dart';
import 'package:ultimate_player/providers/audio_provider.dart';
import 'package:ultimate_player/providers/playlist_provider.dart';
import 'package:uuid/uuid.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  Future<void> _pickFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        final List<Song> newSongs = result.files.map((file) {
          // Handle Web (no path, use bytes) vs Mobile/Desktop (path available)
          final String path = kIsWeb ? 'web_memory_file' : (file.path ?? '');
          final Uint8List? bytes = kIsWeb ? file.bytes : null;

          return Song(
            id: const Uuid().v4(),
            title: file.name.replaceAll('.mp3', ''),
            artist: 'Unknown Artist',
            album: 'Local Import',
            audioPath: path,
            audioBytes: bytes,
          );
        }).toList();

        if (context.mounted) {
          await Provider.of<PlaylistProvider>(context, listen: false)
              .addSongsToPlaylist(playlist, newSongs);
        }
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text(playlist.name, style: const TextStyle(color: CupertinoColors.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _pickFiles(context),
          child: const Icon(CupertinoIcons.music_note_list, color: CupertinoColors.systemGreen),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
             // Playlist Header
             const SizedBox(height: 20),
             Container(
               width: 160,
               height: 160,
               decoration: BoxDecoration(
                 color: CupertinoColors.secondarySystemBackground,
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(color: CupertinoColors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                 ],
               ),
               child: const Icon(CupertinoIcons.music_albums, size: 60, color: CupertinoColors.systemGrey),
             ),
             const SizedBox(height: 16),
             Text(
               "${playlist.songs.length} Songs",
               style: const TextStyle(color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.w500),
             ),
             const SizedBox(height: 20),
             
             // Play Button
             if (playlist.songs.isNotEmpty)
               CupertinoButton.filled(
                 borderRadius: BorderRadius.circular(30),
                 child: const Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(CupertinoIcons.play_fill),
                     SizedBox(width: 8),
                     Text("Play All"),
                   ],
                 ),
                 onPressed: () {
                    Provider.of<AudioProvider>(context, listen: false).playPlaylist(playlist.songs);
                 },
               ),
             
             const SizedBox(height: 20),
             
             // Song List
             Expanded(
               child: Consumer<PlaylistProvider>( // Listen to updates (e.g. after adding songs)
                 builder: (context, provider, child) {
                    // Re-fetch playlist? Or assume the object passed is mutated?
                    // Hive objects update in place usually, but let's be safe:
                   return ListView.builder(
                     itemCount: playlist.songs.length,
                     itemBuilder: (context, index) {
                       final song = playlist.songs[index];
                       return Material(
                         color: Colors.transparent,
                         child: ListTile(
                           leading: const Icon(CupertinoIcons.music_note_2, color: CupertinoColors.systemGrey),
                           title: Text(song.title, style: const TextStyle(color: CupertinoColors.label)),
                           subtitle: Text(song.artist, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                           onTap: () {
                             Provider.of<AudioProvider>(context, listen: false)
                                .playPlaylist(playlist.songs, initialIndex: index);
                           },
                           trailing: CupertinoButton(
                             padding: EdgeInsets.zero,
                             child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.systemGrey),
                             onPressed: () {
                               // TODO: Delete options etc
                             },
                           ),
                         ),
                       );
                     },
                   );
                 },
               ),
             ),
             
             const SizedBox(height: 60), // MiniPlayer padding
          ],
        ),
      ),
    );
  }
}
