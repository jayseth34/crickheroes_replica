import 'package:flutter/material.dart';
import 'player_details_page.dart';

class SearchPlayerPage extends StatefulWidget {
  const SearchPlayerPage({super.key});

  @override
  State<SearchPlayerPage> createState() => _SearchPlayerPageState();
}

class _SearchPlayerPageState extends State<SearchPlayerPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock players data
  final List<Map<String, dynamic>> allPlayers = [
    {
      'name': 'John Doe',
      'photoUrl': null,
      'sports': ['Cricket', 'Football'],
      'tournaments': ['Cricket Premier League', 'Football Cup 2025'],
      'totalMatches': 18,
      'totalRuns': 754,
      'goals': 5,
    },
    {
      'name': 'Emma Smith',
      'photoUrl': null,
      'sports': ['Cricket'],
      'tournaments': ['Cricket Premier League'],
      'totalMatches': 10,
      'totalRuns': 480,
      'goals': 0,
    },
    {
      'name': 'Liam Brown',
      'photoUrl': null,
      'sports': ['Football'],
      'tournaments': ['Football Cup 2025'],
      'totalMatches': 12,
      'totalRuns': 0,
      'goals': 7,
    },
    {
      'name': 'Sophia Lee',
      'photoUrl': null,
      'sports': ['Pickleball'],
      'tournaments': ['Pickleball Masters'],
      'totalMatches': 8,
      'totalRuns': 0,
      'goals': 0,
    },
  ];

  List<Map<String, dynamic>> filteredPlayers = [];

  @override
  void initState() {
    super.initState();
    filteredPlayers = allPlayers;
    _searchController.addListener(_filterPlayers);
  }

  void _filterPlayers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPlayers = allPlayers
          .where(
            (player) => player['name'].toLowerCase().contains(query),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPlayers);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Players'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search player by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredPlayers.isEmpty
                ? const Center(child: Text('No players found'))
                : ListView.builder(
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: player['photoUrl'] != null
                              ? NetworkImage(player['photoUrl'])
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        ),
                        title: Text(player['name']),
                        subtitle:
                            Text(player['sports'].join(', ')), // e.g. Cricket
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailsPage(player: player),
                            ),
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
