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
      
      // Try to get Audio Only, fallback to Muxed (Video+Audio) if needed
      AudioStreamInfo? audioStreamInfo;
      try {
         audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      } catch (_) {
         // Fallback if no audio-only stream
         if (manifest.muxed.isNotEmpty) {
           // This is technically VideoStreamInfo but implements AudioStreamInfo interface or similar properties
           // youtube_explode_dart stream hierarchy:
           // MuxedStreamInfo extends StreamInfo (has audio)
           // We need to be careful with types. 
           // actually manifest.muxed returns MuxedStreamInfo which works differently.
         }
      }
      
      // Robust Selection
      StreamInfo? streamInfo = audioStreamInfo;
      if (streamInfo == null && manifest.muxed.isNotEmpty) {
         streamInfo = manifest.muxed.withHighestBitrate();
      }

      if (streamInfo == null) {
         throw Exception("No suitable audio stream found.");
      }

      // 3. Prepare File Path
      var dir = await getApplicationDocumentsDirectory();
      // Sanitize filename to avoid filesystem errors
      var safeTitle = video.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      var extension = streamInfo.container.name; // 'mp4' usually
      var filePath = '${dir.path}/$safeTitle.$extension';
      var file = File(filePath);

      // 4. Download Stream
      if (file.existsSync()) {
        file.deleteSync();
      }
      
      var stream = _yt.videos.streamsClient.get(streamInfo);
      var fileStream = file.openWrite();
      
      int totalSize = streamInfo.size.totalBytes;
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
      // Rethrow to let UI catch it and show the red text
      throw Exception("Download Error: $e"); 
    }
  }
  
  void dispose() {
    _yt.close();
  }
}
