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
import 'package:ultimate_player/widgets/mini_player.dart';
import 'package:uuid/uuid.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  Future<void> _pickFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
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
        backgroundColor: CupertinoColors.systemGreen,
        middle: Text(playlist.name, style: const TextStyle(color: CupertinoColors.white)),
        leading: CupertinoNavigationBarBackButton(color: CupertinoColors.white, onPressed: () => Navigator.pop(context)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _pickFiles(context),
          child: const Icon(CupertinoIcons.music_note_list, color: CupertinoColors.systemGreen),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
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
             
              // Play Button & Add Songs
              if (playlist.songs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       CupertinoButton.filled(
                         borderRadius: BorderRadius.circular(30),
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                         child: const Row(
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
                       const SizedBox(width: 16),
                       CupertinoButton(
                         color: CupertinoColors.secondarySystemBackground,
                         borderRadius: BorderRadius.circular(30),
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                         child: const Row(
                           children: [
                             Icon(CupertinoIcons.add, color: CupertinoColors.label),
                             SizedBox(width: 8),
                             Text("Add Songs", style: TextStyle(color: CupertinoColors.label)),
                           ],
                         ),
                         onPressed: () => _pickFiles(context),
                       ),
                    ],
                  ),
                )
              else 
                 CupertinoButton(
                   color: CupertinoColors.systemGreen,
                   borderRadius: BorderRadius.circular(30),
                   child: const Text(
                     "Import Songs", 
                     style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)
                   ),
                   onPressed: () => _pickFiles(context),
                 ),
              
              const SizedBox(height: 10),
              
              // Song List
              Expanded(
                child: Consumer2<PlaylistProvider, AudioProvider>(
                  builder: (context, playlistProvider, audioProvider, child) {
                   // Always fetch the latest version of the playlist
                   // We use 'firstWhere' to find the updated playlist object by ID
                   final currentPlaylist = playlistProvider.playlists.firstWhere(
                      (p) => p.id == playlist.id, 
                      orElse: () => playlist // Fallback
                   );

                   if (currentPlaylist.songs.isEmpty) {
                      return Center(
                        child:Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No songs yet.\nTap 'Add Songs' to start.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: CupertinoColors.systemGrey.withOpacity(0.7)),
                          ),
                        ),
                      );
                   }

                   return ListView.builder(
                     itemCount: currentPlaylist.songs.length,
                     itemBuilder: (context, index) {
                       final song = currentPlaylist.songs[index];
                       final bool isActive = audioProvider.currentSong?.id == song.id;
                       
                       return Material(
                         color: isActive ? CupertinoColors.systemGreen.withOpacity(0.15) : Colors.transparent,
                         child: ListTile(
                           leading: Icon(
                                isActive ? CupertinoIcons.speaker_2_fill : CupertinoIcons.music_note_2, 
                                color: isActive ? CupertinoColors.systemGreen : CupertinoColors.systemGrey
                           ),
                           title: Text(
                               song.title, 
                               style: TextStyle(
                                   // Explicitly using white/label for better visibility in all modes
                                   color: isActive ? CupertinoColors.systemGreen : CupertinoColors.white,
                                   fontWeight: isActive ? FontWeight.bold : FontWeight.w500
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                           ),
                           subtitle: Text(
                               song.artist, 
                               style: TextStyle(
                                 // Explicitly lighter grey for dark mode visibility
                                 color: isActive ? CupertinoColors.systemGreen.withOpacity(0.8) : CupertinoColors.systemGrey2
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                           ),
                           onTap: () {
                             Provider.of<AudioProvider>(context, listen: false)
                                .playPlaylist(currentPlaylist.songs, initialIndex: index);
                           },
                           trailing: CupertinoButton(
                             padding: EdgeInsets.zero,
                             child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.systemGrey),
                             onPressed: () {
                               showCupertinoModalPopup(
                                 context: context,
                                 builder: (context) => CupertinoActionSheet(
                                   title: Text(song.title),
                                   actions: [
                                     CupertinoActionSheetAction(
                                       child: const Text("Add to Playlist..."),
                                       onPressed: () {
                                         Navigator.pop(context); // Close sheet
                                         // Show Playlist Selection Dialog
                                         showCupertinoDialog(
                                           context: context,
                                           builder: (context) {
                                              final allPlaylists = Provider.of<PlaylistProvider>(context, listen: false)
                                                 .playlists
                                                 .where((p) => p.id != currentPlaylist.id) // Exclude current
                                                 .toList();
                                              
                                              return CupertinoAlertDialog(
                                                title: const Text("Add to Playlist"),
                                                content: allPlaylists.isEmpty 
                                                   ? const Text("No other playlists available.")
                                                   : SizedBox(
                                                       height: 200, // Limit height
                                                       child: ListView.builder(
                                                         shrinkWrap: true,
                                                         itemCount: allPlaylists.length,
                                                         itemBuilder: (context, i) {
                                                            final target = allPlaylists[i];
                                                            return CupertinoButton(
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              child: Text(target.name),
                                                              onPressed: () {
                                                                 Provider.of<PlaylistProvider>(context, listen: false)
                                                                    .addSongsToPlaylist(target, [song]);
                                                                 Navigator.pop(context); // Close Dialog
                                                                 // Optional success feedback could be added here
                                                              },
                                                            );
                                                         },
                                                       ),
                                                   ),
                                                actions: [
                                                  CupertinoDialogAction(
                                                    child: const Text("Cancel"),
                                                    onPressed: () => Navigator.pop(context),
                                                  )
                                                ],
                                              );
                                           }
                                         );
                                       },
                                     ),
                                     CupertinoActionSheetAction(
                                       isDestructiveAction: true,
                                       child: const Text("Remove from this Playlist"),
                                       onPressed: () {
                                         Provider.of<PlaylistProvider>(context, listen: false)
                                            .removeSongFromPlaylist(currentPlaylist, song);
                                         Navigator.pop(context);
                                       },
                                     ),
                                   ],
                                   cancelButton: CupertinoActionSheetAction(
                                     child: const Text("Cancel"),
                                     onPressed: () => Navigator.pop(context),
                                   ),
                                 ),
                               );
                             },
                           ),
                         ),
                       );
                     },
                   );
                  },
                ),
              ),
             
             const SizedBox(height: 100), // Space for MiniPlayer
          ],
        ),
      ),
      const Positioned(
        left: 0, 
        right: 0, 
        bottom: 0, 
        child: MiniPlayer(),
      ),
          ],
        ),
      ),
    );
  }
}
