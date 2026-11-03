class Team {
  final String id;
  final String teamName;
  final String hackathon;
  final String leader;
  final String requiredSkills;
  final int maxMembers;
  final List<String> members;
  final String location;

  Team({
    required this.id,
    required this.teamName,
    required this.hackathon,
    required this.leader,
    required this.requiredSkills,
    required this.maxMembers,
    required this.members,
    this.location = '',
  });

  factory Team.fromMap(String id, Map<String, dynamic> data) {
    return Team(
      id: id,
      teamName: data['teamName'] ?? '',
      hackathon: data['hackathon'] ?? '',
      leader: data['leader'] ?? '',
      requiredSkills: data['requiredSkills'] ?? '',
      maxMembers: data['maxMembers'] is int
          ? data['maxMembers']
          : int.tryParse(data['maxMembers'].toString()) ?? 4,
      members: List<String>.from(data['members'] ?? []),
      location: (data['location'] ?? data['city'] ?? data['venue'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamName': teamName,
      'hackathon': hackathon,
      'leader': leader,
      'requiredSkills': requiredSkills,
      'maxMembers': maxMembers,
      'members': members,
      'location': location,
    };
  }
}
