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
    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal during download
      builder: (context) => const DownloadDialog(),
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
          child: const Icon(CupertinoIcons.play_rectangle, color: CupertinoColors.systemRed),
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
      onLongPress: () {
        showCupertinoDialog(
          context: context, 
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Delete Playlist?"),
            content: Text("Are you sure you want to delete '${playlist.name}'?"),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Delete"),
                onPressed: () {
                  Provider.of<PlaylistProvider>(context, listen: false).deletePlaylist(playlist);
                  Navigator.pop(context);
                },
              ),
            ],
          )
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

class DownloadDialog extends StatefulWidget {
  const DownloadDialog({super.key});

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  bool _isDownloading = false;
  String _statusText = "Enter YouTube URL";
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Download from YouTube"),
      content: Column(
        children: [
           const SizedBox(height: 10),
           if (!_isDownloading)
             Column(
               children: [
                 CupertinoTextField(
                   controller: _urlController,
                   placeholder: "https://youtu.be/...",
                   style: const TextStyle(color: CupertinoColors.label),
                 ),
                 if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_errorMessage!, style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
                    )
               ],
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
            onPressed: _startDownload,
          ),
      ],
    );
  }

  Future<void> _startDownload() async {
    if (_urlController.text.isEmpty) {
      showCupertinoDialog(
        context: context, 
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Input Required"),
          content: const Text("Please enter a YouTube URL first."),
          actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context))]
        )
      );
      return;
    }
    
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _statusText = "Analyzing...";
    });
    
    try {
      final ytService = YouTubeService();
      // Listen to the download stream
      final song = await ytService.downloadVideoAsAudio(
        _urlController.text, 
        (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _statusText = "Downloading: ${(progress * 100).toInt()}%";
          });
        },
        onStatus: (status) {
           if (!mounted) return;
           setState(() {
              _statusText = status;
           });
        }
      );
      
      if (!mounted) return;

      if (song != null) {
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
        if (mounted) Navigator.pop(context); // Close dialog on success
      } else {
        setState(() {
          _isDownloading = false;
          _errorMessage = "Invalid video or URL.";
        });
      }
      ytService.dispose();
    } catch (e) {
       if (!mounted) return;
       setState(() {
          _isDownloading = false;
          _errorMessage = "Error: $e";
       });
       showCupertinoDialog(
         context: context,
         builder: (context) => CupertinoAlertDialog(
           title: const Text("Download Failed"),
           content: Text("Could not download video. \n\nDetails: $e"),
           actions: [
             CupertinoDialogAction(
               child: const Text("OK"),
               onPressed: () => Navigator.pop(context),
             )
           ],
         )
       );
    }
  }
}
