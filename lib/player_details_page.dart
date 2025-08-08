import 'package:flutter/material.dart';

class PlayerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerDetailsPage({super.key, required this.player});

  // Define custom colors based on the provided theme from my_profile_page.txt
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    // Extract player data with default values for safety
    final String name = player['name'] ?? 'Unknown Player';
    final String bio =
        'No bio available.'; // Not in new data, using a default static value
    final String role = player['role'] ?? 'N/A';
    final String location = player['village'] ?? 'N/A';
    final String address = player['address'] ?? 'N/A';
    final int age = player['age'] ?? 'N/A';
    final String gender = player['gender'] ?? 'N/A';
    final String handedness = player['handedness'] ?? 'N/A';
    final String phone = player['mobNo'] ?? 'N/A';
    final String email = 'N/A'; // Not in new data
    final List<String> sports = []; // Not in new data, using empty list
    final List<String> achievements = []; // Not in new data, using empty list
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
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: primaryBlue,
            backgroundImage: NetworkImage(photoUrl),
            onBackgroundImageError: (exception, stackTrace) {
              // This is a simple fallback. A more robust solution might use a stateful widget
              // to update the image provider to a placeholder image after a load error.
            },
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
          const Divider(color: Colors.white38, height: 20, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentOrange, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}
