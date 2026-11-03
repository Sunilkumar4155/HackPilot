import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/team.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new team
  Future<void> createTeam(Team team) async {
    await _firestore.collection('teams').add(team.toMap());
  }

  // Get all teams
  Stream<List<Team>> getTeams() {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      final list = <Team>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(Team.fromMap(doc.id, doc.data()));
        } catch (e) {
          debugPrint('HACKPILOT: Skipped malformed team doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  // Join a team
  Future<void> joinTeam(String teamId, String userEmail) async {
    final teamRef = _firestore.collection('teams').doc(teamId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(teamRef);
      if (!snapshot.exists) {
        throw StateError('This team is no longer available.');
      }
      final data = snapshot.data() ?? <String, dynamic>{};
      final members = List<String>.from(data['members'] ?? const <String>[]);
      if (members.contains(userEmail)) {
        return;
      }
      final maxMembers = data['maxMembers'] is int
          ? data['maxMembers'] as int
          : int.tryParse('${data['maxMembers']}') ?? 4;
      if (members.length >= maxMembers) {
        throw StateError('This team is already full.');
      }
      transaction.update(teamRef, {
        'members': [...members, userEmail],
      });
    });
  }
}
