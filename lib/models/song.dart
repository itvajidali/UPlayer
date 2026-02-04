import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String? artPath; // Local path to image, or null for default

  @HiveField(5)
  final String audioPath; // Local path to audio file (Mobile/Desktop)

  @HiveField(6)
  final Uint8List? audioBytes; // Audio data (Web)

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.artPath,
    required this.audioPath,
    this.audioBytes,
  });
}
