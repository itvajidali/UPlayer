import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ultimate_player/models/playlist.dart';
import 'package:ultimate_player/models/song.dart';
import 'package:uuid/uuid.dart';

class PlaylistProvider extends ChangeNotifier {
  static const String boxName = 'playlists_box';
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final box = await Hive.openBox<Playlist>(boxName);
    _playlists = box.values.toList();
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final box = await Hive.openBox<Playlist>(boxName);
    final newPlaylist = Playlist(
      id: const Uuid().v4(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
    );
    
    await box.add(newPlaylist); // Hive adds it and assigns a key if needed, but we used auto-increment or key? 
    // HiveObject extends enables saving. 
    // Better to use put with ID if we want specific keys, or just add.
    // For simplicity with Hive list:
    _playlists.add(newPlaylist);
    newPlaylist.save(); // Save to box
    
    notifyListeners();
  }

  Future<void> addSongsToPlaylist(Playlist playlist, List<Song> newSongs) async {
    playlist.songs.addAll(newSongs);
    playlist.save(); // Persist changes
    notifyListeners();
  }
  
  Future<void> deletePlaylist(Playlist playlist) async {
      await playlist.delete();
      _playlists.remove(playlist);
      notifyListeners();
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, Song song) async {
    playlist.songs.removeWhere((s) => s.id == song.id);
    playlist.save();
    notifyListeners();
  }
}
