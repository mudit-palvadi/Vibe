import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:vibe/core/services/recently_played_service.dart';
import 'package:vibe/core/services/session_storage.dart';
import 'package:vibe/core/theme/theme.dart';
import 'package:vibe/feature/auth/view/pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //initialize hive
  await Hive.initFlutter();
  await RecentlyPlayedService.init();
  await SessionStorage.init();

  //load .env
  await dotenv.load(fileName: ".env");

  //just audio init
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkMode,
      home: const AuthWrapper(),
    );
  }
}
