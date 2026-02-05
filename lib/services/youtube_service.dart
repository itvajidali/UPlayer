import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';
import 'package:uuid/uuid.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<Song?> downloadVideoAsAudio(String url, Function(double) onProgress) async {
    try {
      // 1. Get Video Metadata
      // Use VideoId.parse to handle various URL formats safely
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) return null;
      
      var video = await _yt.videos.get(videoId);

      // 2. Get Manifest
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      // Prefer m4a (mp4 container auth audio) which plays natively on iOS/Android
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // 3. Prepare File Path
      var dir = await getApplicationDocumentsDirectory();
      // Sanitize filename to avoid filesystem errors
      var safeTitle = video.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      var filePath = '${dir.path}/$safeTitle.m4a';
      var file = File(filePath);

      // 4. Download Stream
      if (file.existsSync()) {
        file.deleteSync();
      }
      
      var stream = _yt.videos.streamsClient.get(audioStreamInfo);
      var fileStream = file.openWrite();
      
      int totalSize = audioStreamInfo.size.totalBytes;
      int received = 0;

      await for (var data in stream) {
        received += data.length;
        fileStream.add(data);
        onProgress(received / totalSize);
      }
      
      await fileStream.flush();
      await fileStream.close();

      // 5. Create Song Object
      return Song(
        id: const Uuid().v4(),
        title: video.title,
        artist: video.author,
        album: 'YouTube Downloads',
        audioPath: filePath,
      );

    } catch (e) {
      print('Error downloading: $e');
      return null;
    }
  }
  
  void dispose() {
    _yt.close();
  }
}
