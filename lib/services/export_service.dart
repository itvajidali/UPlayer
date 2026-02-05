import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';

class ExportService {
  
  /// Opens the system share sheet (Android/iOS) to let the user save or share the file.
  /// Returns a status message (or null if action is purely UI driven).
  Future<String> exportSong(Song song) async {
    try {
      final File sourceFile = File(song.audioPath);
      if (!await sourceFile.exists()) {
        return "Error: Source file not found";
      }

      // Convert file to XFile for sharing
      final XFile xFile = XFile(
        sourceFile.path,
        name: "${song.title}.m4a", // Use .m4a for audio-only MP4 container
        mimeType: 'audio/mp4',
      );

      // Trigger Share Sheet
      // The user can choose "Save to Files" (iOS) or "Copy to..." (Android)
      final result = await Share.shareXFiles(
        [xFile],
        text: "Sharing ${song.title}",
      );

      if (result.status == ShareResultStatus.success) {
         return "Shared successfully";
      } else if (result.status == ShareResultStatus.dismissed) {
         return "Export cancelled";
      }
      return "Export action completed";
      
    } catch (e) {
      return "Export failed: $e";
    }
  }
}
