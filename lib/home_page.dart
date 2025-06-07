import 'package:flutter/material.dart';
import 'search_tournament_page.dart';
import 'view_tournaments_page.dart';
import 'search_player_page.dart';
import 'my_profile_page.dart'; // Added import for profile page
import 'add_tournament_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tournaments = [
      {'title': 'Cricket Premier League', 'date': 'Starts May 10'},
      {'title': 'Football Cup 2025', 'date': 'Starts June 1'},
      {'title': 'Pickleball Masters', 'date': 'Starts May 20'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricheroes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTournamentPage()),
          );
        },
        tooltip: "Add a Tournament",
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
                  builder: (_) => SearchTournamentPage(mode: 'addTeam'),
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
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tournaments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = tournaments[index];
                  return _buildTournamentCard(item['title']!, item['date']!);
                },
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 1.2),
            _sectionTitle("About the App"),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Cricheroes is your all-in-one tournament manager that makes organizing sports events easy and powerful.",
                style: TextStyle(fontSize: 14),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _FeatureItem(
                      icon: Icons.sports_cricket,
                      text: "Create and manage multi-sport tournaments"),
                  _FeatureItem(
                      icon: Icons.people,
                      text: "Register teams and players with full profiles"),
                  _FeatureItem(
                      icon: Icons.gavel,
                      text: "Conduct live or offline auctions"),
                  _FeatureItem(
                      icon: Icons.schedule,
                      text: "Auto-generate match fixtures and stats"),
                  _FeatureItem(
                      icon: Icons.analytics,
                      text: "Track performance and analyze player data"),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Built for tournament organizers, coaches, and sports lovers.",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: Colors.blue.shade700),
      accountName: const Text(
        "User Name",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      accountEmail: const Text("user@example.com"),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.blue.shade700,
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildTournamentCard(String title, String date) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.lightBlue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emoji_events, size: 40, color: Colors.orange),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
    );
  }
}
