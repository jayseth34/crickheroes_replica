import 'package:flutter/material.dart';

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage>
    with TickerProviderStateMixin {
  late TabController _teamTabController;

  @override
  void initState() {
    super.initState();
    _teamTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _teamTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    final List<Map<String, dynamic>> teamABatting = [
      {
        'name': 'Virat Kohli',
        'runs': 76,
        'balls': 59,
        'fours': 6,
        'sixes': 2,
        'sr': 128.81,
        'dismissal': 'c Rabada b Jansen'
      },
      {
        'name': 'Axar Patel',
        'runs': 47,
        'balls': 31,
        'fours': 1,
        'sixes': 4,
        'sr': 151.61,
        'dismissal': 'run out (de Kock)'
      },
      {
        'name': 'Rohit Sharma',
        'runs': 28,
        'balls': 22,
        'fours': 3,
        'sixes': 1,
        'sr': 127.27,
        'dismissal': 'b Nortje'
      },
      {
        'name': 'Suryakumar Yadav',
        'runs': 10,
        'balls': 6,
        'fours': 2,
        'sixes': 0,
        'sr': 166.67,
        'dismissal': 'c Klaasen b Maharaj'
      },
    ];

    final List<Map<String, dynamic>> teamABowling = [
      {
        'name': 'Jasprit Bumrah',
        'overs': 4,
        'maidens': 0,
        'runs': 18,
        'wickets': 2,
        'economy': 4.50
      },
      {
        'name': 'Hardik Pandya',
        'overs': 3,
        'maidens': 0,
        'runs': 20,
        'wickets': 3,
        'economy': 6.67
      },
      {
        'name': 'Axar Patel',
        'overs': 4,
        'maidens': 0,
        'runs': 28,
        'wickets': 1,
        'economy': 7.00
      },
    ];

    final List<Map<String, dynamic>> teamBBatting = [
      {
        'name': 'Quinton de Kock',
        'runs': 64,
        'balls': 45,
        'fours': 7,
        'sixes': 1,
        'sr': 142.22,
        'dismissal': 'b Bumrah'
      },
      {
        'name': 'Temba Bavuma',
        'runs': 34,
        'balls': 30,
        'fours': 4,
        'sixes': 0,
        'sr': 113.33,
        'dismissal': 'run out (Axar)'
      },
      {
        'name': 'Heinrich Klaasen',
        'runs': 55,
        'balls': 35,
        'fours': 5,
        'sixes': 2,
        'sr': 157.14,
        'dismissal': 'c Kohli b Pandya'
      },
    ];

    final List<Map<String, dynamic>> teamBBowling = [
      {
        'name': 'Kagiso Rabada',
        'overs': 4,
        'maidens': 0,
        'runs': 32,
        'wickets': 1,
        'economy': 8.00
      },
      {
        'name': 'Anrich Nortje',
        'overs': 4,
        'maidens': 0,
        'runs': 29,
        'wickets': 2,
        'economy': 7.25
      },
      {
        'name': 'Keshav Maharaj',
        'overs': 3,
        'maidens': 0,
        'runs': 24,
        'wickets': 1,
        'economy': 8.00
      },
    ];

    final List<Map<String, dynamic>> overByOver = List.generate(
        20,
        (i) => {
              'over': i + 1,
              'runs': (5 + i % 4),
              'wickets': (i % 7 == 0) ? 1 : 0,
            });

    return Scaffold(
      appBar: AppBar(
        title: Text(match['match']),
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _teamTabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.deepPurple.shade400,
              ),
              tabs: const [
                Tab(text: 'Team A'),
                Tab(text: 'Team B'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _teamTabController,
        children: [
          _buildTeamStats('Team A Batting', teamABatting, 'Team A Bowling',
              teamABowling, overByOver),
          _buildTeamStats('Team B Batting', teamBBatting, 'Team B Bowling',
              teamBBowling, overByOver),
        ],
      ),
    );
  }

  Widget _buildTeamStats(
      String battingTitle,
      List<Map<String, dynamic>> battingStats,
      String bowlingTitle,
      List<Map<String, dynamic>> bowlingStats,
      List<Map<String, dynamic>> overSummary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(battingTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Batsman')),
                DataColumn(label: Text('R')),
                DataColumn(label: Text('B')),
                DataColumn(label: Text('4s')),
                DataColumn(label: Text('6s')),
                DataColumn(label: Text('SR')),
                DataColumn(label: Text('Dismissal')),
              ],
              rows: battingStats.map((player) {
                return DataRow(cells: [
                  DataCell(Text(player['name'])),
                  DataCell(Text(player['runs'].toString())),
                  DataCell(Text(player['balls'].toString())),
                  DataCell(Text(player['fours'].toString())),
                  DataCell(Text(player['sixes'].toString())),
                  DataCell(Text(player['sr'].toString())),
                  DataCell(SizedBox(
                    width: 100, // prevent overflow
                    child: Text(
                      player['dismissal'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(bowlingTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Bowler')),
                DataColumn(label: Text('O')),
                DataColumn(label: Text('M')),
                DataColumn(label: Text('R')),
                DataColumn(label: Text('W')),
                DataColumn(label: Text('Econ')),
              ],
              rows: bowlingStats.map((bowler) {
                return DataRow(cells: [
                  DataCell(Text(bowler['name'])),
                  DataCell(Text(bowler['overs'].toString())),
                  DataCell(Text(bowler['maidens'].toString())),
                  DataCell(Text(bowler['runs'].toString())),
                  DataCell(Text(bowler['wickets'].toString())),
                  DataCell(Text(bowler['economy'].toString())),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Over-by-Over Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: overSummary.length,
            itemBuilder: (context, index) {
              final over = overSummary[index];
              return ListTile(
                leading: Text('Over ${over['over']}'),
                title: Text('Runs: ${over['runs']}'),
                trailing: Text('Wickets: ${over['wickets']}'),
              );
            },
          ),
        ],
      ),
    );
  }
}
