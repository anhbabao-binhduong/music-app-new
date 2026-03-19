import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteCubit extends Cubit<List<String>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _authSub;
  StreamSubscription? _favoritesSub;

  FavoriteCubit() : super([]) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _favoritesSub?.cancel();

      if (user != null) {
        _bindFavoritesStream(user.uid);
      } else {
        emit([]);
      }
    });
  }

  CollectionReference<Map<String, dynamic>> _favoriteCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  String _favoriteDocId(String songId) => base64Url.encode(utf8.encode(songId));

  void _bindFavoritesStream(String uid) {
    _favoritesSub = _favoriteCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final savedIds = snapshot.docs
            .map((doc) => (doc.data()['songId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
        emit(savedIds);
      },
      onError: (e) {
        print('Lỗi realtime yêu thích từ Firestore: $e');
      },
    );
  }

  Future<void> toggleFavorite(String songId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để dùng yêu thích');
    }

    final isLiked = state.contains(songId);

    try {
      final docRef = _favoriteCollection(user.uid).doc(_favoriteDocId(songId));
      if (isLiked) {
        await docRef.delete();
      } else {
        await docRef.set({
          'songId': songId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Lỗi đồng bộ yêu thích với Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _favoritesSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
