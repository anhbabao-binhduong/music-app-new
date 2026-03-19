import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadCubit extends Cubit<List<String>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _authSub;
  StreamSubscription? _downloadsSub;

  DownloadCubit() : super([]) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _downloadsSub?.cancel();

      if (user != null) {
        _bindDownloadsStream(user.uid);
      } else {
        emit([]);
      }
    });
  }

  CollectionReference<Map<String, dynamic>> _downloadCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('downloads');
  }

  String _downloadDocId(String songId) => base64Url.encode(utf8.encode(songId));

  void _bindDownloadsStream(String uid) {
    _downloadsSub = _downloadCollection(uid)
        .orderBy('downloadedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final ids = snapshot.docs
          .map((doc) => (doc.data()['songId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();
      emit(ids);
    }, onError: (e) {
      print('Lỗi realtime downloads từ Firestore: $e');
    });
  }

  Future<void> toggleDownload(MediaItem song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để lưu nhạc đã tải');
    }

    final isDownloaded = state.contains(song.id);
    final docRef = _downloadCollection(user.uid).doc(_downloadDocId(song.id));

    if (isDownloaded) {
      await docRef.delete();
      return;
    }

    await docRef.set({
      'songId': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'artUrl': song.artUri?.toString(),
      'audioUrl': song.id,
      'downloadedAt': FieldValue.serverTimestamp(),
      'status': 'saved',
    });
  }

  @override
  Future<void> close() async {
    await _downloadsSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
