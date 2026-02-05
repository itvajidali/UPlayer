import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, InkWell, Colors, Icons, LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:provider/provider.dart';
import 'package:ultimate_player/models/playlist.dart';
import 'package:ultimate_player/providers/playlist_provider.dart';
import 'package:ultimate_player/screens/playlist_detail_screen.dart';
import 'package:ultimate_player/services/youtube_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showDownloadDialog(BuildContext context) {
    final TextEditingController _urlController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: true, // Allow clicking outside to dismiss if stuck
      builder: (context) {
        // Use a StatefulWidget to handle local state (progress)
        return StatefulBuilder(
          builder: (context, setState) {
            double _progress = 0.0;
            bool _isDownloading = false;
            String _statusText = "Enter YouTube URL";

            return CupertinoAlertDialog(
              title: const Text("Download from YouTube"),
              content: Column(
                children: [
                   const SizedBox(height: 10),
                   if (!_isDownloading)
                     CupertinoTextField(
                       controller: _urlController,
                       placeholder: "https://youtu.be/...",
                       style: const TextStyle(color: CupertinoColors.label),
                     )
                   else
                     Column(
                       children: [
                         Text(_statusText, style: const TextStyle(fontSize: 12)),
                         const SizedBox(height: 10),
                         LinearProgressIndicator(value: _progress, backgroundColor: CupertinoColors.systemGrey5, valueColor: const AlwaysStoppedAnimation(CupertinoColors.systemGreen)),
                       ],
                     ),
                ],
              ),
              actions: [
                if (!_isDownloading)
                  CupertinoDialogAction(
                    child: const Text("Cancel"),
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                if (!_isDownloading)
                  CupertinoDialogAction(
                    child: const Text("Download"),
                    isDefaultAction: true,
                    onPressed: () async {
                       if (_urlController.text.isEmpty) return;
                       
                       setState(() {
                         _isDownloading = true;
                         _statusText = "Analyzing...";
                       });
                       
                       // Start Download
                       try {
                         final ytService = YouTubeService();
                         final song = await ytService.downloadVideoAsAudio(
                           _urlController.text, 
                           (progress) {
                              setState(() {
                                _progress = progress;
                                _statusText = "Downloading: ${(progress * 100).toInt()}%";
                              });
                           }
                         );
                         
                         if (song != null) {
                            if (context.mounted) {
                              // Add to "Downloads" playlist
                              final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                              // Find or create "Downloads" playlist
                              var downloadPlaylist = playlistProvider.playlists.firstWhere(
                                (p) => p.name == "Downloads",
                                orElse: () { 
                                   playlistProvider.createPlaylist("Downloads");
                                   return playlistProvider.playlists.firstWhere((p) => p.name == "Downloads");
                                }
                              );
                              
                              await playlistProvider.addSongsToPlaylist(downloadPlaylist, [song]);
                              Navigator.pop(context); // Close dialog
                            }
                         } else {
                            setState(() {
                              _isDownloading = false;
                              _statusText = "Download Failed. Check URL.";
                            });
                         }
                         ytService.dispose();
                       } catch (e) {
                          setState(() {
                             _isDownloading = false;
                             _statusText = "Error: $e";
                          });
                       }
                    },
                  ),
              ],
            );
          }
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("New Playlist"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: _controller,
            placeholder: "Playlist Name",
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("Create"),
            isDefaultAction: true,
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                Provider.of<PlaylistProvider>(context, listen: false)
                    .createPlaylist(_controller.text);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGreen,
        middle: const Text('Playlists', style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.cloud_download, color: CupertinoColors.white),
          onPressed: () => _showDownloadDialog(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showCreatePlaylistDialog(context),
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.white),
        ),
      ),
      child: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          final playlists = playlistProvider.playlists;
          
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.music_albums, size: 80, color: CupertinoColors.systemGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No Playlists",
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    child: const Text("Create your first playlist"),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final playlist = playlists[index];
                      return _PlaylistCard(playlist: playlist);
                    },
                    childCount: playlists.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for MiniPlayer
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistCard({required this.playlist});

  LinearGradient _getGradient(String name) {
    // Deterministic random colors based on name
    final int hash = name.hashCode;
    
    final movements = [
      // Purple-Pink
      const LinearGradient(
         colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      // Orange-Red
      const LinearGradient(
         colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      // Green-Teal
      const LinearGradient(
         colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      // Blue-Cyan
      const LinearGradient(
         colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      // Pink-Gold
      const LinearGradient(
         colors: [Color(0xFFDA4453), Color(0xFF89216B)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
       // Midnight
      const LinearGradient(
         colors: [Color(0xFF232526), Color(0xFF414345)],
         begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ];
    
    return movements[hash.abs() % movements.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(playlist.name);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                // Removed image overlay to guarantee gradient visibility and fix "White Card" issue
              ),
              child: Stack(
                children: [
                   if (playlist.songs.isEmpty)
                      const Center(child: Icon(CupertinoIcons.music_note, size: 50, color: Colors.white54)),
                   
                   Positioned(
                     bottom: 12,
                     left: 12,
                     right: 12,
                     child: Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                     ),
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding( // Just song count below
             padding: const EdgeInsets.only(left: 4),
             child: Text(
               "${playlist.songs.length} songs",
               style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13, fontWeight: FontWeight.w500),
             ),
          ),
        ],
      ),
    );
  }
}
