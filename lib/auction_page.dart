import 'package:flutter/material.dart';

class AuctionPage extends StatefulWidget {
  final String tournamentName;

  const AuctionPage({required this.tournamentName, Key? key}) : super(key: key);

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  final int basePrice = 100;
  int currentBid = 100;
  String playerName = "Player 1";
  String? selectedTeam;
  String? soldTo;

  final List<Map<String, dynamic>> teams = [
    {
      'name': 'Team A',
      'wallet': 1000,
      'logo': 'https://via.placeholder.com/100/FF0000/FFFFFF?text=A',
    },
    {
      'name': 'Morkhiya stallions',
      'wallet': 800,
      'logo': 'https://via.placeholder.com/100/00FF00/FFFFFF?text=B',
    },
    {
      'name': 'RSBL',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'Riddhi siddhi bullions limited',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'The shah and nahar cup',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'Team F',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
  ];

  void increaseBid(String teamName) {
    final team = teams.firstWhere((t) => t['name'] == teamName);
    if (team['wallet'] < currentBid + 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$teamName has insufficient funds!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      currentBid += 10;
      selectedTeam = teamName;
    });
  }

  void assignPlayer() {
    if (selectedTeam == null) return;

    final team = teams.firstWhere((t) => t['name'] == selectedTeam);
    if (team['wallet'] < currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedTeam has insufficient funds!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      soldTo = selectedTeam;
      team['wallet'] -= currentBid;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Player Assigned'),
        content: Text('Player sold to $selectedTeam for ₹$currentBid'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                refreshPlayer();
              },
              child: const Text('OK'))
        ],
      ),
    );
  }

  void markUnsold() {
    setState(() {
      soldTo = 'Unsold';
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Player Unsold'),
        content: const Text('Player was marked as unsold.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                refreshPlayer();
              },
              child: const Text('OK'))
        ],
      ),
    );
  }

  void resetBid() {
    setState(() {
      currentBid = basePrice;
      selectedTeam = null;
    });
  }

  void refreshPlayer() {
    setState(() {
      playerName = "Player ${DateTime.now().second}";
      currentBid = basePrice;
      selectedTeam = null;
      soldTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auction - ${widget.tournamentName}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              NetworkImage('https://via.placeholder.com/150'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          playerName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Base Price: ₹$basePrice',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Bid: ₹$currentBid',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Teams (Tap to Raise Bid)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: teams.map((team) {
                    final isSelected = team['name'] == selectedTeam;
                    return GestureDetector(
                      onTap: () => increaseBid(team['name']),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: isSelected ? 36 : 32,
                            backgroundColor:
                                isSelected ? Colors.amber : Colors.transparent,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(team['logo']),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 80,
                            child: Tooltip(
                              message: team['name'],
                              child: Text(
                                team['name'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          Text(
                            '₹${team['wallet']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedTeam != null && soldTo == null
                            ? assignPlayer
                            : null,
                        icon: const Icon(Icons.gavel),
                        label: const Text(""),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffc5a3fb),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: soldTo == null ? markUnsold : null,
                        icon: const Icon(Icons.cancel),
                        label: const Text("Mark Unsold"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: soldTo == null ? resetBid : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset Bid"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xfff9c4c4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
