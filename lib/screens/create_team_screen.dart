import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final teamNameController = TextEditingController();
  final hackathonController = TextEditingController();
  final locationController = TextEditingController();
  final skillsController = TextEditingController();
  final maxMembersController = TextEditingController(text: '4');
  final TeamService teamService = TeamService();
  bool isSubmitting = false;

  @override
  void dispose() {
    teamNameController.dispose();
    hackathonController.dispose();
    locationController.dispose();
    skillsController.dispose();
    maxMembersController.dispose();
    super.dispose();
  }

  Future<void> createTeam() async {
    if (isSubmitting || !_formKey.currentState!.validate()) return;
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with an email address to create a team.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => isSubmitting = true);
    try {
      await teamService.createTeam(
        Team(
          id: '',
          teamName: teamNameController.text.trim(),
          hackathon: hackathonController.text.trim(),
          leader: email,
          requiredSkills: skillsController.text.trim(),
          maxMembers: int.parse(maxMembersController.text.trim()),
          members: [email],
          location: locationController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team created successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create this team. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Create New Team'),
        elevation: 0,
        backgroundColor: colors.background,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.18),
                          colors.violet.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Icon(Icons.groups_rounded, color: colors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HACKPILOT TEAM BUILDER',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Assemble Your Hackathon Crew',
                                style: TextStyle(
                                  color: Color(0xFFF5F7FA),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text(
                    'Team Details',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share the hackathon and the specific skills your team needs.',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 22),

                  // Team name
                  TextFormField(
                    controller: teamNameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: colors.ink),
                    decoration: InputDecoration(
                      labelText: 'Team name',
                      labelStyle: TextStyle(color: colors.muted),
                      hintText: 'e.g. Neural Ninjas, CyberSprint, OrbitDev',
                      hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.badge_outlined, color: colors.primary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a team name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Hackathon or project name
                  TextFormField(
                    controller: hackathonController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: colors.ink),
                    decoration: InputDecoration(
                      labelText: 'Hackathon or challenge name',
                      labelStyle: TextStyle(color: colors.muted),
                      hintText: 'e.g. Global AI Agents Hackathon',
                      hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.emoji_events_outlined, color: colors.primary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter the hackathon or project'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Location / Format (optional)
                  TextFormField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: colors.ink),
                    decoration: InputDecoration(
                      labelText: 'Location / Format (optional)',
                      labelStyle: TextStyle(color: colors.muted),
                      hintText: 'e.g. Online, San Francisco, CA, or Hybrid',
                      hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.location_on_outlined, color: colors.primary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skills looking for
                  TextFormField(
                    controller: skillsController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    style: TextStyle(color: colors.ink),
                    decoration: InputDecoration(
                      labelText: 'Skills you are looking for',
                      labelStyle: TextStyle(color: colors.muted),
                      hintText: 'e.g. Flutter, Machine Learning, UI/UX, Backend',
                      hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.code_rounded, color: colors.primary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add at least one skill or role'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Maximum team size
                  TextFormField(
                    controller: maxMembersController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.ink),
                    decoration: InputDecoration(
                      labelText: 'Maximum team size (including you)',
                      labelStyle: TextStyle(color: colors.muted),
                      prefixIcon: Icon(Icons.group_outlined, color: colors.primary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      final count = int.tryParse(value?.trim() ?? '');
                      if (count == null || count < 2 || count > 20) {
                        return 'Enter a number between 2 and 20';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : createTeam,
                      icon: isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.group_add_rounded, size: 18),
                      label: Text(
                        isSubmitting ? 'Creating Team…' : 'Create Team',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
