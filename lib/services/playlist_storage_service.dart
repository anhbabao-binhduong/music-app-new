import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/playlist_model.dart';

class PlaylistStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _playlistCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('playlists');
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để dùng danh sách phát');
    }
    return uid;
  }

  List<PlaylistModel> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final playlists = docs.map((doc) {
      final data = doc.data();
      final rawSongIds = data['songIds'];
      final rawCreatedAt = data['createdAt'];

      return PlaylistModel(
        id: doc.id,
        name: (data['name'] ?? 'Untitled Playlist').toString(),
        songIds: rawSongIds is List ? rawSongIds.map((e) => e.toString()).toList() : <String>[],
        createdAt: rawCreatedAt is Timestamp
            ? rawCreatedAt.toDate()
            : DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
        coverArtUrl: data['coverArtUrl']?.toString(),
      );
    }).toList();

    playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return playlists;
  }

  Future<List<PlaylistModel>> fetchPlaylists() async {
    final uid = _requireUid();
    final snapshot = await _playlistCollection(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return _mapDocs(snapshot.docs);
  }

  Future<String> createPlaylist(String name) async {
    final uid = _requireUid();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Tên danh sách phát không được để trống');
    }

    final existing = await _playlistCollection(uid)
        .where('nameLower', isEqualTo: trimmedName.toLowerCase())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Danh sách phát đã tồn tại');
    }

    final doc = _playlistCollection(uid).doc();
    await doc.set({
      'name': trimmedName,
      'nameLower': trimmedName.toLowerCase(),
      'songIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'coverArtUrl': null,
      'visibility': 'private',
    });

    return doc.id;
  }

  Future<DocumentReference<Map<String, dynamic>>> _playlistRef(String playlistId) async {
    final uid = _requireUid();
    final docRef = _playlistCollection(uid).doc(playlistId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Không tìm thấy danh sách phát');
    }

    return docRef;
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final docRef = await _playlistRef(playlistId);
    await docRef.set({
      'songIds': FieldValue.arrayUnion([songId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    final docRef = await _playlistRef(playlistId);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final songIds = (data['songIds'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    if (oldIndex < 0 || oldIndex >= songIds.length) return;
    if (newIndex < 0 || newIndex > songIds.length) return;

    if (newIndex > oldIndex) newIndex -= 1;
    final item = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, item);

    await docRef.update({
      'songIds': songIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final docRef = await _playlistRef(playlistId);
    await docRef.set({
      'songIds': FieldValue.arrayRemove([songId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePlaylist(String playlistId) async {
    final docRef = await _playlistRef(playlistId);
    await docRef.delete();
  }
}
