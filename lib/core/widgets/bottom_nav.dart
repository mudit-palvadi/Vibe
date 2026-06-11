import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:vibe/core/theme/app_colors.dart';
import 'package:vibe/feature/home/view/pages/home_page.dart';
import 'package:vibe/feature/music/view/widgets/music_slab.dart';
import 'package:vibe/feature/library/view/pages/library_page.dart';
import 'package:vibe/feature/music/view/pages/music_upload_page.dart';
import 'package:vibe/feature/search/view/pages/search_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final pages = [
    const HomePage(),
    const SearchPage(),
    const MusicUploadPage(),
    const LibraryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VibeColors.navbar,
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(index: currentIndex, children: pages),
              const Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: MusicSlab(),
              ),
            ],
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: currentIndex,
            backgroundColor: VibeColors.navbar.withValues(alpha: 0),
            color: VibeColors.navbar,
            buttonBackgroundColor: VibeColors.navbar,
            animationDuration: const Duration(milliseconds: 350),
            items: const [
              Icon(Icons.home_rounded, color: Colors.white),
              Icon(Icons.search_rounded, color: Colors.white),
              Icon(Icons.upload_rounded, color: Colors.white),
              Icon(Icons.library_music_rounded, color: Colors.white),
            ],

            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
