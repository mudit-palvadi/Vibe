import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibe/core/providers/recently_played_provider.dart';
import 'package:vibe/core/utils.dart';
import 'package:vibe/feature/home/model/song_model.dart';
import 'package:vibe/feature/music/viewmodel/upload_viewmodel.dart';

part 'current_song_notifier.g.dart';

@Riverpod(keepAlive: true)
class CurrentQueue extends _$CurrentQueue {
  @override
  List<SongModel> build() {
    return [];
  }

  void setQueue(List<SongModel> queue) {
    state = queue;
  }
}

@Riverpod(keepAlive: true)
AudioPlayer audioPlayerInstance(Ref ref) {
  final player = AudioPlayer();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
}

@riverpod
Future<Color> currentSongColor(Ref ref) async {
  final currentSong = ref.watch(currentSongProvider);
  if (currentSong == null) {
    return Colors.black;
  }
  return generatePalette(currentSong.thumbnail_url);
}

@Riverpod(keepAlive: true)
class CurrentSongNotifier extends _$CurrentSongNotifier {
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? _latestRequestedSongId;

  @override
  SongModel? build() {
    ref.onDispose(() {
      _playerStateSubscription?.cancel();
    });
    return null;
  }

  void updateSong(SongModel song) async {
    _latestRequestedSongId = song.id;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;

    final player = ref.read(audioPlayerInstanceProvider);

    try {
      await player.stop();
      if (_latestRequestedSongId != song.id) return;

      state = song;
      ref.read(recentlyPlayedProvider.notifier).addSong(song);

      final audioSource = AudioSource.uri(
        Uri.parse(song.song_url),
        tag: MediaItem(
          id: song.id,
          title: song.song_name,
          artist: song.artist,
          artUri: Uri.parse(song.thumbnail_url),
        ),
      );

      await player.setAudioSource(audioSource);
      if (_latestRequestedSongId != song.id) return;

      _playerStateSubscription = player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          _playerStateSubscription?.cancel();
          _playerStateSubscription = null;
          Future.microtask(() => _playNextSong());
        }
      });
      player.play();
    } catch (e, st) {
      final errorStr = e.toString();
      if (e is! PlayerInterruptedException && !errorStr.contains('PlayerInterruptedException') && !errorStr.contains('Connection aborted')) {
        developer.log('Audio player error', error: e, stackTrace: st);
      }
      if (_latestRequestedSongId == song.id) {
        state = null;
      }
    }
  }

  void _playNextSong() {
    final songsAsync = ref.read(getAllSongsProvider);
    final queue = ref.read(currentQueueProvider);
    final songs = queue.isNotEmpty ? queue : (songsAsync.value ?? []);

    final currentSong = state;
    if (currentSong == null || songs.isEmpty) return;

    final index = songs.indexWhere((s) => s.id == currentSong.id);
    if (index != -1) {
      final nextSong = songs[(index + 1) % songs.length];
      updateSong(nextSong);
    }
  }

  void playPause() {
    final player = ref.read(audioPlayerInstanceProvider);

    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void stopSong() async {
    _latestRequestedSongId = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    state = null;
    final player = ref.read(audioPlayerInstanceProvider);
    await player.stop();
  }
}

@riverpod
Stream<bool> isPlaying(Ref ref) {
  final player = ref.watch(audioPlayerInstanceProvider);
  return player.playingStream;
}

@riverpod
Stream<Duration?> currentSongDuration(Ref ref) {
  final player = ref.watch(audioPlayerInstanceProvider);
  return player.durationStream;
}

@riverpod
Stream<Duration> currentSongPosition(Ref ref) {
  final player = ref.watch(audioPlayerInstanceProvider);
  return player.positionStream;
}
