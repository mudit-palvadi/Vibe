import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibe/core/constants.dart';
import 'package:vibe/core/failure/failure.dart';
import 'package:vibe/core/services/api_service.dart';
import 'package:vibe/feature/home/model/song_model.dart';

part 'music_repository.g.dart';

@riverpod
MusicRepository musicRepository(Ref ref) {
  return MusicRepository();
}

class MusicRepository {
  Future<Either<AppFailure, String>> uploadSong({
    required File audio,
    required File image,
    required String artist,
    required String songName,
    required String tags,
    required String token,
  }) async {
    try {
      // the server tells where the files should go
      final initResponse = await http.post(
        Uri.parse('${ServerConstant.serverURL}/song/upload-init'),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
        body: jsonEncode({
          'song_name': songName,
          'artist': artist,
          'tags': tags,
          'audio_filename': _fileName(audio.path),
          'thumbnail_filename': _fileName(image.path),
        }),
      );

      if (initResponse.statusCode != 201) {
        return Left(AppFailure(ApiService.detailOf(initResponse)));
      }

      final initBody = jsonDecode(initResponse.body) as Map<String, dynamic>;
      final audioPart = initBody['audio'] as Map<String, dynamic>;
      final thumbnailPart = initBody['thumbnail'] as Map<String, dynamic>;

      // the files go straight to the storage
      await _putFile(audioPart, audio);
      await _putFile(thumbnailPart, image);

      // then the server makes the song
      final completeResponse = await http.post(
        Uri.parse('${ServerConstant.serverURL}/song/upload-complete'),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
        body: jsonEncode({
          'song_id': initBody['song_id'],
          'song_name': songName,
          'artist': artist,
          'tags': tags,
          'audio_key': audioPart['key'],
          'thumbnail_key': thumbnailPart['key'],
        }),
      );

      if (completeResponse.statusCode != 201) {
        return Left(AppFailure(ApiService.detailOf(completeResponse)));
      }

      final data = jsonDecode(completeResponse.body);

      return Right(data['message']);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  /// puts a file on the link the server gave
  Future<void> _putFile(Map<String, dynamic> part, File file) async {
    final request = http.StreamedRequest('PUT', Uri.parse(part['url']));

    request.headers.addAll(Map<String, String>.from(part['headers'] ?? {}));
    request.contentLength = await file.length();
    request.sink.addStream(file.openRead());

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('The file could not be uploaded');
    }
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[/\\]'));

    return parts.isEmpty ? 'file' : parts.last;
  }

  Future<Either<AppFailure, List<SongModel>>> getAllSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/song/list'),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }

      resBodyMap = resBodyMap as List;
      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getAllFavSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/song/list-favourites'),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }

      resBodyMap = resBodyMap as List;
      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map['song']));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, bool>> favSong({
    required String songId,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/song/favourite'),
        body: jsonEncode({'song_id': songId}),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200 && res.statusCode != 201) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Failed to toggle favourite'));
      }

      return Right(resBodyMap['message']);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> searchSongs({
    required String query,
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/song/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          ServerConstant.sessionHeader: token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Search failed'));
      }

      resBodyMap = resBodyMap as List;
      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
