import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hackathon.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Hackathon>> getHackathons() {
    return _firestore
        .collection('hackathon collections')
        .snapshots()
        .map((snapshot) {
      final list = <Hackathon>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(Hackathon.fromMap(doc.id, doc.data()));
        } catch (e) {
          debugPrint('HACKPILOT: Skipped malformed hackathon doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }
}
