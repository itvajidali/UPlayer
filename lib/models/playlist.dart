import 'package:hive/hive.dart';
import 'package:ultimate_player/models/song.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<Song> songs;

  @HiveField(3)
  DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
  });
}
