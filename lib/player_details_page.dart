import 'package:flutter/material.dart';
import 'dart:convert';

class PlayerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerDetailsPage({super.key, required this.player});

  // Define custom colors based on the provided theme from my_profile_page.txt
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    // Extract player data with default values for safety and correct data types
    final String name = player['name'] ?? 'Unknown Player';
    final String bio = player['bio'] ?? 'No bio available.';
    final String role = player['role'] ?? 'N/A';
    final String location = player['village'] ?? 'N/A';
    final String address = player['address'] ?? 'N/A';
    final String age = (player['age'] is int)
        ? player['age'].toString()
        : player['age']?.toString() ?? 'N/A';
    final String gender = player['gender'] ?? 'N/A';
    final String handedness = player['handedness'] ?? 'N/A';
    final String phone = player['mobNo'] ?? 'N/A';
    final String email = player['email'] ?? 'N/A';
    final String favSport = player['favSport'] ?? 'N/A';
    final String playingStyle = player['playingStyle'] ?? 'N/A';

    final List<String> sports = _parseNestedList(player['sports']);
    final List<String> achievements = _parseNestedList(player['achievements']);
    final List<Map<String, dynamic>> tournaments =
        (player['tournaments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final String photoUrl = player['profileImage'] ??
        'https://placehold.co/200x200/F26C4F/1A0F49?text=Player'; // Placeholder image

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: lightBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(
              context,
              name,
              photoUrl,
              bio,
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              title: 'Personal Information',
              children: [
                _buildInfoRow(icon: Icons.person, label: 'Role', value: role),
                _buildInfoRow(
                    icon: Icons.location_on, label: 'Village', value: location),
                _buildInfoRow(
                    icon: Icons.home, label: 'Address', value: address),
                _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Age',
                    value: age.toString()),
                _buildInfoRow(
                    icon: Icons.people, label: 'Gender', value: gender),
                _buildInfoRow(
                    icon: Icons.handshake,
                    label: 'Handedness',
                    value: handedness),
                _buildInfoRow(
                    icon: Icons.sports,
                    label: 'Favorite Sport',
                    value: favSport),
                _buildInfoRow(
                    icon: Icons.sports_tennis,
                    label: 'Playing Style',
                    value: playingStyle),
                _buildInfoRow(icon: Icons.phone, label: 'Phone', value: phone),
                _buildInfoRow(icon: Icons.email, label: 'Email', value: email),
              ],
            ),
            _buildInfoCard(
              title: 'Sports & Achievements',
              children: [
                _buildSectionTitle('Sports'),
                const SizedBox(height: 10),
                _buildSportsChips(sports),
                const SizedBox(height: 20),
                _buildSectionTitle('Achievements'),
                const SizedBox(height: 10),
                _buildAchievementList(achievements),
                const SizedBox(height: 20),
                _buildSectionTitle('Tournaments'),
                const SizedBox(height: 10),
                _buildTournamentList(tournaments),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helper function to parse a nested JSON array string ---
  List<String> _parseNestedList(dynamic data) {
    if (data is List<String>) {
      // Check if the first item is a JSON string
      try {
        final decoded = json.decode(data.first);
        if (decoded is List) {
          return decoded.whereType<String>().toList();
        }
      } catch (_) {
        // If decoding fails, return the original list
        return data;
      }
    }

    if (data is List && data.isNotEmpty && data[0] is String) {
      try {
        final decodedList = json.decode(data[0]);
        return decodedList.whereType<String>().toList();
      } catch (e) {
        print('Error decoding nested list: $e');
        return [];
      }
    }

    return [];
  }

  // --- Reusable Widgets for Profile & Details Pages ---

  Widget _buildProfileHeader(
      BuildContext context, String name, String photoUrl, String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: accentOrange,
            child: CircleAvatar(
              radius: 56,
              backgroundImage: NetworkImage(photoUrl),
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading image: $exception');
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        color: const Color(0xFF2E1C59),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white54, height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSportsChips(List<String> sports) {
    if (sports.isEmpty) {
      return const Text(
        "No sports information available.",
        style: TextStyle(color: Colors.white70),
      );
    }
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: sports.map((sport) {
        return Chip(
          label: Text(sport),
          backgroundColor: accentOrange.withOpacity(0.7),
          labelStyle: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementList(List<String> achievements) {
    if (achievements.isEmpty) {
      return const Text(
        "No achievements yet.",
        style: TextStyle(color: Colors.white70),
      );
    }
    return Column(
      children: achievements.map((achievement) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.star, color: accentOrange),
          title: Text(
            achievement,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTournamentList(List<Map<String, dynamic>> tournaments) {
    if (tournaments.isEmpty) {
      return const Text(
        "No tournaments yet.",
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: tournaments.map((tournament) {
        final String name =
            tournament['tournamentName'] ?? 'Unknown Tournament';
        final String start = tournament['startDate'] ?? '';
        final String end = tournament['endDate'] ?? '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.emoji_events, color: accentOrange),
          title: Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'From $start to $end',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}
