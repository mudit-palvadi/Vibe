import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe/core/providers/current_song_notifier.dart';
import 'package:vibe/core/providers/current_user_notifier.dart';
import 'package:vibe/core/providers/recently_played_provider.dart';
import 'package:vibe/core/theme/app_colors.dart';
import 'package:vibe/feature/home/model/song_model.dart';
import 'package:vibe/feature/music/viewmodel/upload_viewmodel.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _showOnlyFavorites = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: VibeColors.backgroundColor,
      surfaceTintColor: VibeColors.backgroundColor,
      pinned: true,
      centerTitle: false,
      title: const Text(
        'Your Library',
        style: TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: VibeColors.white,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Image.asset('lib/core/icons/logo_transparent.png', height: 35),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildChip("Favorites", _showOnlyFavorites),
        const SizedBox(width: 12),
        _buildChip("All Tracks", !_showOnlyFavorites),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showOnlyFavorites = label == "Favorites";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? VibeColors.brightPurple : VibeColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VibeColors.brightPurple : VibeColors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: VibeColors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLikedSongsHeaderCard(int count, List<SongModel> songs, bool isPlayingFav) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VibeColors.deepBlue, VibeColors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: VibeColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.heart_fill,
                  color: VibeColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Liked Songs",
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: VibeColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$count songs",
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 14,
                      color: VibeColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (songs.isEmpty) return;
              if (isPlayingFav) {
                ref.read(currentSongProvider.notifier).playPause();
              } else {
                ref.read(currentQueueProvider.notifier).setQueue(songs);
                ref.read(currentSongProvider.notifier).updateSong(songs.first);
              }
            },
            child: CircleAvatar(
              backgroundColor: VibeColors.white,
              radius: 28,
              child: Icon(
                isPlayingFav ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid,
                color: VibeColors.deepBlue,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed(List<SongModel> recentlyPlayed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recently Played",
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: VibeColors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentlyPlayed.length,
            itemBuilder: (context, index) {
              final song = recentlyPlayed[index];
              return GestureDetector(
                onTap: () {
                  ref.read(currentQueueProvider.notifier).setQueue(recentlyPlayed);
                  ref.read(currentSongProvider.notifier).updateSong(song);
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnail_url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: VibeColors.card,
                            child: const Icon(CupertinoIcons.music_note, color: VibeColors.inactive),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.song_name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'SF Pro',
                          color: VibeColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          color: VibeColors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: VibeColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VibeColors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: VibeColors.white),
        cursorColor: VibeColors.brightPurple,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            CupertinoIcons.search,
            color: VibeColors.inactive,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: VibeColors.inactive,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          hintText: "Search in Library",
          hintStyle: const TextStyle(
            color: VibeColors.inactive,
            fontFamily: 'SF Pro',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
      ),
    );
  }

  Widget _buildSongTile(SongModel song, List<SongModel> queue, List<dynamic> userFavourites) {
    final currentSong = ref.watch(currentSongProvider);
    final isCurrentTrack = currentSong?.id == song.id;
    final isFav = userFavourites.any((fav) => fav.songId == song.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(currentQueueProvider.notifier).setQueue(queue);
          ref.read(currentSongProvider.notifier).updateSong(song);
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: song.thumbnail_url,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 55,
                  height: 55,
                  color: VibeColors.card,
                  child: const Icon(CupertinoIcons.music_note, color: VibeColors.inactive),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.song_name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      color: isCurrentTrack ? VibeColors.brightPurple : VibeColors.white,
                      fontSize: 15,
                      fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          color: VibeColors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.check_circle,
                        color: VibeColors.white.withValues(alpha: 0.5),
                        size: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: isFav ? VibeColors.brightPurple : VibeColors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () async {
                await ref
                    .read(uploadViewModelProvider.notifier)
                    .favSong(songId: song.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSongsAsync = _showOnlyFavorites
        ? ref.watch(getAllFavSongsProvider)
        : ref.watch(getAllSongsProvider);

    final userFavourites = ref.watch(
      currentUserProvider.select((data) => data?.favSongs ?? []),
    );
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;

    return Scaffold(
      backgroundColor: VibeColors.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),
          ),
          ...activeSongsAsync.when<List<Widget>>(
            data: (songs) {
              final filteredSongs = songs.where((song) {
                final query = _searchQuery.toLowerCase();
                return song.song_name.toLowerCase().contains(query) ||
                    song.artist.toLowerCase().contains(query);
              }).toList();

              final isPlayingActiveList = currentSong != null &&
                  isPlaying &&
                  songs.any((s) => s.id == currentSong.id);

              return [
                if (_searchQuery.isEmpty && recentlyPlayed.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildRecentlyPlayed(recentlyPlayed),
                    ),
                  ),
                if (_showOnlyFavorites && _searchQuery.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverToBoxAdapter(
                      child: _buildLikedSongsHeaderCard(songs.length, songs, isPlayingActiveList),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),
                ),
                if (filteredSongs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.music_note_list,
                            color: VibeColors.white.withValues(alpha: 0.2),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "No tracks match your search"
                                : _showOnlyFavorites
                                    ? "No liked songs yet"
                                    : "No tracks available",
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              color: VibeColors.white.withValues(alpha: 0.4),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = filteredSongs[index];
                          return _buildSongTile(song, filteredSongs, userFavourites);
                        },
                        childCount: filteredSongs.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ];
            },
            error: (error, stackTrace) => [
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: VibeColors.error),
                  ),
                ),
              ),
            ],
            loading: () => [
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(VibeColors.brightPurple),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
