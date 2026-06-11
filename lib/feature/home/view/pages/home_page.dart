import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe/core/constants.dart';
import 'package:vibe/core/theme/app_colors.dart';
import 'package:vibe/core/providers/current_user_notifier.dart';
import 'package:vibe/core/widgets/home_appbar.dart';
import 'package:vibe/feature/home/view/widgets/music_mix_carousel.dart';
import 'package:vibe/feature/home/view/widgets/playlist_carousel.dart';
import 'package:vibe/feature/home/view/widgets/user_header.dart';
import 'package:vibe/feature/music/viewmodel/upload_viewmodel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsList = ref.watch(getAllSongsProvider);
    final userName = ref.watch(currentUserProvider)?.name.split(' ')[0] ?? '';

    return Scaffold(
      body: songsList.when(
        data: (songs) {
          return CustomScrollView(
            slivers: [
              HomeAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibePadding.horizontalPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      UserHeader(userName: userName),

                      MusicMixCarousel(songs: songs),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Popular Playlist",
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const Text(
                            "View all",
                            style: TextStyle(
                              color: VibeColors.greyText,
                              fontFamily: 'SF Pro',
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      PlaylistCarousel(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(
          child: CircularProgressIndicator(color: VibeColors.brightPurple),
        ),
      ),
    );
  }
}
