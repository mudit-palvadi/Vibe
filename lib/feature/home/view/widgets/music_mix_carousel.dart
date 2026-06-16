import 'package:coverflow_carousel/coverflow_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:precached_network_image/precached_network_image.dart';
import 'package:vibe/core/providers/current_song_notifier.dart';
import 'package:vibe/core/theme/app_colors.dart';
import 'package:vibe/feature/home/model/song_model.dart';

class MusicMixCarousel extends ConsumerStatefulWidget {
  final List<SongModel> songs;

  const MusicMixCarousel({super.key, required this.songs});

  @override
  ConsumerState<MusicMixCarousel> createState() => _MusicMixCarouselState();
}

class _MusicMixCarouselState extends ConsumerState<MusicMixCarousel> {
  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: CoverflowCarousel.builder(
        itemCount: widget.songs.length,
        itemWidth: 180,
        itemHeight: 180,
        scrollDirection: Axis.horizontal,
        initialPage: widget.songs.length ~/ 2,
        nearCardSpacing: 40,
        farCardSpacing: 45,
        entryAnimation: CoverflowEntryAnimation.spacingExpand,
        entryAnimationDuration: const Duration(milliseconds: 1000),
        entryAnimationCurve: Curves.easeOutBack,
        centerOverlayBuilder: (context, index) {
          final song = widget.songs[index];
          return Positioned(
            bottom: -30,
            right: 62,
            child: GestureDetector(
              onTap: () {
                ref.read(currentQueueProvider.notifier).setQueue([]);
                ref.read(currentSongProvider.notifier).updateSong(song);
              },
              child: CircleAvatar(
                radius: 30,
                backgroundColor: VibeColors.backgroundColor,
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: VibeColors.white,
                  child: Icon(
                    CupertinoIcons.play_fill,
                    color: VibeColors.backgroundColor,
                  ),
                ),
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final song = widget.songs[index];
          return GestureDetector(
            onTap: () {
              ref.read(currentQueueProvider.notifier).setQueue([]);
              ref.read(currentSongProvider.notifier).updateSong(song);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PrecachedNetworkImage(
                height: 180,
                width: 180,
                precache: true,
                url: song.thumbnail_url,
                fit: BoxFit.cover,
                placeholder: (_, _) {
                  return Container(
                    width: 180,
                    height: 180,
                    color: VibeColors.deepBlue,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
