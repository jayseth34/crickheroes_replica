import 'package:flutter/material.dart';
import 'search_tournament_page.dart';
import 'view_tournaments_page.dart';
import 'search_player_page.dart';
import 'my_profile_page.dart';
import 'add_tournament_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    final tournaments = [
      {
        'title': 'Cricket Premier League',
        'date': 'Starts May 10',
        'image':
            'https://images.unsplash.com/photo-1597773151122-c3473f88033f' // Replace with better asset/image if needed
      },
      {
        'title': 'Football Cup 2025',
        'date': 'Starts June 1',
        'image': 'https://images.unsplash.com/photo-1549924231-f129b911e442'
      },
      {
        'title': 'Pickleball Masters',
        'date': 'Starts May 20',
        'image': 'https://images.unsplash.com/photo-1666802069460-f8350592bb96'
      },
    ];

    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      appBar: AppBar(
        title: const Text('Cricheroes', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTournamentPage()),
          );
        },
        tooltip: "Add a Tournament",
        backgroundColor: accentOrange, // Set FAB to accentOrange
        foregroundColor: Colors.white, // White icon
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildUserHeader(context),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyProfilePage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.add,
              title: 'Add Tournament',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTournamentPage()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.group_add,
              title: 'Add Teams',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchTournamentPage(mode: 'addTeam', isAdmin: true),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_add,
              title: 'Add Player',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchTournamentPage(mode: 'addPlayer'),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.gavel,
              title: 'Auction',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchTournamentPage(mode: 'auction'),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.visibility,
              title: 'View Tournaments',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewTournamentsPage(),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_search,
              title: 'View Players',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchPlayerPage(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Upcoming Tournaments"),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true, // Enables leftward scrolling
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tournaments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = tournaments[index];
                  return _buildTournamentCard(
                    item['title']!,
                    item['date']!,
                    item['image']!,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            const Divider(
                thickness: 1.2, color: Colors.white30), // Divider color
            _sectionTitle("About the App"),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Cricheroes is your all-in-one tournament manager that makes organizing sports events easy and powerful.",
                style: TextStyle(
                    fontSize: 14, color: Colors.white70), // Text color
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _FeatureItem(
                    icon: Icons.sports_cricket,
                    text: "Create and manage multi-sport tournaments",
                  ),
                  _FeatureItem(
                    icon: Icons.people,
                    text: "Register teams and players with full profiles",
                  ),
                  _FeatureItem(
                    icon: Icons.gavel,
                    text: "Conduct live or offline auctions",
                  ),
                  _FeatureItem(
                    icon: Icons.schedule,
                    text: "Auto-generate match fixtures and stats",
                  ),
                  _FeatureItem(
                    icon: Icons.analytics,
                    text: "Track performance and analyze player data",
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Built for tournament organizers, coaches, and sports lovers.",
                style: TextStyle(
                    fontSize: 14, color: Colors.white70), // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: lightBlue),
      accountName: const Text(
        "User Name",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      accountEmail: const SizedBox.shrink(), // 👈 hides email cleanly
      currentAccountPicture: CircleAvatar(
        backgroundColor: accentOrange,
        child: const Icon(
          Icons.person,
          size: 50,
          color: Colors.white,
        ),
      ),
      margin: EdgeInsets.zero,
      onDetailsPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyProfilePage()),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white), // White text
        ),
      );

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: accentOrange), // Accent orange icon
      title: Text(title,
          style: const TextStyle(color: primaryBlue)), // Primary blue text
      onTap: onTap,
    );
  }

  Widget _buildTournamentCard(String title, String date, String imageUrl) {
    return SizedBox(
      width: 270,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: lightBlue.withOpacity(0.7), // Card background with opacity
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: primaryBlue
                      .withOpacity(0.5)), // Primary blue with opacity
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white), // White text
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: TextStyle(color: Colors.white70), // White70 text
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accentOrange), // Accent orange icon
      title:
          Text(text, style: const TextStyle(color: Colors.white)), // White text
    );
  }
}
