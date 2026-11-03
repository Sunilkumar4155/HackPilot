import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addBookmark({
    required String hackathonId,
    required Map<String, dynamic> data,
  }) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(hackathonId)
        .set(data);
  }

  Future<void> removeBookmark(String hackathonId) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(hackathonId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBookmarks() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .snapshots();
  }

  Stream<Set<String>> getBookmarkIds() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <String>{});
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }
}
