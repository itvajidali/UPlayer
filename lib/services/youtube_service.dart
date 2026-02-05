import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';
import 'package:uuid/uuid.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<Song?> downloadVideoAsAudio(
      String url, 
      Function(double) onProgress,
      {Function(String)? onStatus}
  ) async {
    http.Client? client;
    try {
      onStatus?.call("Parsing URL...");
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) {
        return null; 
      }
      
      onStatus?.call("Fetching metadata...");
      var video = await _yt.videos.get(videoId);
      
      onStatus?.call("Fetching manifest...");
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      onStatus?.call("Selecting stream...");
      StreamInfo? streamInfo;
      
      // RESTORED LEGACY LOGIC: Muxed first (Most reliable)
      if (manifest.muxed.isNotEmpty) {
         streamInfo = manifest.muxed.withHighestBitrate();
      }
      
      // Fallback
      if (streamInfo == null) {
         try {
            streamInfo = manifest.audioOnly.withHighestBitrate();
         } catch (_) {}
      }

      if (streamInfo == null) {
         throw Exception("No suitable stream found.");
      }

      var dir = await getApplicationDocumentsDirectory();
      var safeTitle = video.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      var extension = streamInfo.container.name; // Usually 'mp4'

      var filePath = '${dir.path}/$safeTitle.$extension';
      var file = File(filePath);

      if (file.existsSync()) {
        file.deleteSync();
      }
      
      onStatus?.call("Starting download...");
      
      // RESTORED LEGACY NETWORK LOGIC
      client = http.Client();
      final request = http.Request('GET', streamInfo.url);
      // Restore the UA that was working originally
      request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      
      final response = await client.send(request).timeout(
         const Duration(seconds: 30),
         onTimeout: () {
            throw TimeoutException("Connection timed out");
         }
      );
      
      if (response.statusCode != 200) {
         throw Exception("HTTP Error ${response.statusCode}");
      }

      var fileStream = file.openWrite();
      int totalSize = streamInfo.size.totalBytes;
      int received = 0;
      
      await response.stream.forEach((chunk) {
         received += chunk.length;
         fileStream.add(chunk);
         // Standard progress update
         onProgress(received / totalSize);
      });
      
      await fileStream.flush();
      await fileStream.close();

      return Song(
        id: const Uuid().v4(),
        title: video.title,
        artist: video.author,
        album: 'YouTube Downloads',
        audioPath: filePath,
        audioBytes: null, 
      );

    } catch (e, stack) {
      print('Error downloading: $e');
      print(stack);
      throw Exception("Download Error: $e"); 
    } finally {
      client?.close();
    }
  }
  
  void dispose() {
    _yt.close();
  }
}
