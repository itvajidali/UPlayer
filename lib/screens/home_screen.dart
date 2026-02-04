import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, InkWell, Colors, Icons;
import 'package:provider/provider.dart';
import 'package:ultimate_player/models/playlist.dart';
import 'package:ultimate_player/providers/playlist_provider.dart';
import 'package:ultimate_player/screens/playlist_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        backgroundColor: CupertinoColors.systemBackground,
        middle: const Text('Playlists', style: TextStyle(color: CupertinoColors.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showCreatePlaylistDialog(context),
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.systemGreen),
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
                    style: TextStyle(color: CupertinoColors.label.withOpacity(0.5), fontSize: 20),
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

  @override
  Widget build(BuildContext context) {
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
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                image: playlist.songs.isNotEmpty && playlist.songs.first.artPath != null
                    ? DecorationImage(
                        image: NetworkImage(playlist.songs.first.artPath!), // TODO: FileImage for local
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: playlist.songs.isEmpty
                  ? const Center(child: Icon(CupertinoIcons.music_note, size: 40, color: CupertinoColors.systemGrey))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: const TextStyle(color: CupertinoColors.label, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${playlist.songs.length} songs",
            style: const TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
