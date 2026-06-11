import 'package:cached_network_image/cached_network_image.dart';
import 'package:coverflow_carousel/coverflow_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibe/core/constants.dart';
import 'package:vibe/core/providers/current_song_notifier.dart';
import 'package:vibe/core/providers/current_user_notifier.dart';
import 'package:vibe/core/theme/app_colors.dart';
import 'package:vibe/core/widgets/adaptive_background.dart';
import 'package:vibe/feature/music/view/widgets/lyrics_bottom_sheet.dart';
import 'package:vibe/feature/music/view/widgets/waveform_scrubber.dart';
import 'package:vibe/feature/music/viewmodel/upload_viewmodel.dart';

class MusicPlayer extends ConsumerStatefulWidget {
  const MusicPlayer({super.key});

  @override
  ConsumerState<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends ConsumerState<MusicPlayer> {
  late CoverflowCarouselController _carouselController;
  int? _carouselPageIndex;
  String? _lastSongId;

  @override
  void initState() {
    super.initState();
    _carouselController = CoverflowCarouselController();
  }

  @override
  Widget build(BuildContext context) {
    final userFavourites = ref.watch(
      currentUserProvider.select((data) => data?.favSongs ?? []),
    );
    final currentSong = ref.watch(currentSongProvider);
    final currentSongColorAsync = ref.watch(currentSongColorProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final isPlaying = isPlayingAsync.value ?? false;

    final positionAsync = ref.watch(currentSongPositionProvider);
    final songsAsync = ref.watch(getAllSongsProvider);
    final queue = ref.watch(currentQueueProvider);

    final songs = queue.isNotEmpty ? queue : (songsAsync.value ?? []);
    final dominantColor = currentSongColorAsync.value ?? VibeColors.deepBlue;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song is currently playing')),
      );
    }

    // Synchronize carousel index on external song changes (like next/prev buttons)
    if (currentSong.id != _lastSongId) {
      final index = songs.indexWhere((s) => s.id == currentSong.id);
      if (index != -1) {
        if (_lastSongId != null && index != _carouselPageIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _carouselController.animateTo(index);
          });
        }
        _lastSongId = currentSong.id;
        _carouselPageIndex = index;
      }
    }

    void skipNext() {
      if (songs.isEmpty) return;
      final index = songs.indexWhere((s) => s.id == currentSong.id);
      if (index != -1) {
        final nextSong = songs[(index + 1) % songs.length];
        ref.read(currentSongProvider.notifier).updateSong(nextSong);
      }
    }

    void skipPrevious() {
      if (songs.isEmpty) return;
      final index = songs.indexWhere((s) => s.id == currentSong.id);
      if (index != -1) {
        final position = positionAsync.value ?? Duration.zero;
        if (position.inSeconds > 3) {
          ref.read(audioPlayerInstanceProvider).seek(Duration.zero);
        } else {
          final prevSong = songs[(index - 1 + songs.length) % songs.length];
          ref.read(currentSongProvider.notifier).updateSong(prevSong);
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          AdaptiveBackground(dominantColor: dominantColor),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VibePadding.horizontalPadding,
                vertical: VibePadding.verticalPadding,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: CircleAvatar(
                          backgroundColor: VibeColors.inactive.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_down,
                            color: VibeColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: VibeColors.white.withValues(alpha: 0.7),
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: CircleAvatar(
                          backgroundColor: VibeColors.inactive.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis_vertical,
                            color: VibeColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: CoverflowCarousel.builder(
                      itemCount: songs.isEmpty ? 1 : songs.length,
                      itemWidth: MediaQuery.of(context).size.width * 0.82,
                      itemHeight: MediaQuery.of(context).size.width * 0.82,
                      initialPage: songs.isNotEmpty
                          ? songs
                                .indexWhere((s) => s.id == currentSong.id)
                                .clamp(0, songs.length - 1)
                          : 0,
                      controller: _carouselController,
                      visibleItems: 1,
                      nearCardSpacing: MediaQuery.of(context).size.width * 0.82,
                      viewportFraction: 0.8,
                      skewAngle: 0,
                      onPageChanged: (index) {
                        if (songs.isNotEmpty &&
                            index >= 0 &&
                            index < songs.length) {
                          final song = songs[index];
                          if (song.id != currentSong.id) {
                            setState(() {
                              _carouselPageIndex = index;
                            });
                            ref
                                .read(currentSongProvider.notifier)
                                .updateSong(song);
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        final song = songs.isNotEmpty
                            ? songs[index]
                            : currentSong;
                        final isCurrentSong = song.id == currentSong.id;

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrentSong
                                    ? dominantColor.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.2),
                                blurRadius: 35,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Hero(
                              tag: isCurrentSong
                                  ? 'music-player-art-${song.id}'
                                  : 'music-player-art-inactive-${song.id}',
                              child: CachedNetworkImage(
                                imageUrl: song.thumbnail_url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<LoopMode>(
                        stream: ref
                            .watch(audioPlayerInstanceProvider)
                            .loopModeStream,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          final isRepeating = loopMode == LoopMode.one;
                          return IconButton(
                            onPressed: () {
                              final player = ref.read(
                                audioPlayerInstanceProvider,
                              );
                              if (isRepeating) {
                                player.setLoopMode(LoopMode.off);
                              } else {
                                player.setLoopMode(LoopMode.one);
                              }
                            },
                            icon: Icon(
                              isRepeating
                                  ? CupertinoIcons.repeat_1
                                  : CupertinoIcons.repeat,
                              size: 22,
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              currentSong.song_name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentSong.artist,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 16,
                                fontWeight: FontWeight.w200,
                                color: VibeColors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await ref
                              .read(uploadViewModelProvider.notifier)
                              .favSong(songId: currentSong.id);
                        },
                        icon: Builder(
                          builder: (context) {
                            final isFav = userFavourites.any(
                              (fav) => fav.songId == currentSong.id,
                            );
                            return Icon(
                              isFav
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: isFav
                                  ? VibeColors.pink
                                  : VibeColors.white.withValues(alpha: 0.6),
                              size: 22,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  WaveformScrubber(
                    song: currentSong,
                    activeColor: VibeColors.white,
                    isPlaying: isPlaying,
                  ),

                  const Spacer(flex: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: skipPrevious,
                        icon: const Icon(
                          CupertinoIcons.backward_end_fill,
                          color: VibeColors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: () {
                          ref.read(currentSongProvider.notifier).playPause();
                        },
                        child: CircleAvatar(
                          backgroundColor: VibeColors.white.withValues(
                            alpha: 0.3,
                          ),
                          radius: 30,
                          child: Icon(
                            isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_arrow_solid,
                            color: VibeColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      IconButton(
                        onPressed: skipNext,
                        icon: const Icon(
                          CupertinoIcons.forward_end_fill,
                          color: VibeColors.white,
                          size: 25,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 6),
                ],
              ),
            ),
          ),

          LyricsBottomSheet(
            songName: currentSong.song_name,
            artist: currentSong.artist,
            dominantColor: dominantColor,
          ),
        ],
      ),
    );
  }
}
