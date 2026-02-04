import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:ultimate_player/models/song.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  AudioPlayer get audioPlayer => _audioPlayer;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Song? get currentSong => _queue.isNotEmpty && _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  AudioProvider() {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
      
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
        if (index != null && index != _currentIndex) {
            _currentIndex = index;
            notifyListeners();
        }
    });
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _queue = List.from(songs);
    _currentIndex = initialIndex;
    notifyListeners();

    try {
      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) {
            // Handle Web or Bytes
            if (kIsWeb && song.audioBytes != null) {
              // Creating a data URI is memory intensive but works for Web demo without file access
              // Ideally for larger files a Blob URL is needed, but just_audio handles URIs.
             return AudioSource.uri(
                Uri.dataFromBytes(song.audioBytes!, mimeType: 'audio/mpeg'),
                tag: MediaItem(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    displayDescription: song.album,
                ),
             );
            }

            return AudioSource.uri(
                Uri.file(song.audioPath), 
                tag: MediaItem(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    displayDescription: song.album,
                ),
            );
        }).toList(),
      );
      
      await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing playlist: $e");
    }
  }

  Future<void> skipToNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
