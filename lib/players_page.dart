import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Define the Player class to model the API response
class Player {
  final int id;
  final String name;
  final String village;
  final int age;
  final String address;
  final String role;
  final String profileImage;
  final String gender;
  final String handedness;

  Player({
    required this.id,
    required this.name,
    required this.village,
    required this.age,
    required this.address,
    required this.role,
    required this.profileImage,
    required this.gender,
    required this.handedness,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      name: json['name'] as String,
      village: json['village'] as String,
      age: json['age'] as int,
      address: json['address'] as String,
      role: json['role'] as String,
      profileImage: json['profileImage'] as String,
      gender: json['gender'] as String,
      handedness: json['handedness'] as String,
    );
  }
}

class PlayersPage extends StatefulWidget {
  final int teamId;

  const PlayersPage({super.key, required this.teamId});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

  List<Player> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse(
        "https://sportsdecor.somee.com/api/Player/GetPlayerListByTeam/${widget.teamId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _players = data.map((p) => Player.fromJson(p)).toList();
        });
      } else {
        setState(() {
          _error = "Failed to load players: Status ${response.statusCode}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching players: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryBlue,
        body: Center(child: CircularProgressIndicator(color: accentOrange)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: primaryBlue,
        appBar: AppBar(
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: lightBlue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Players',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: lightBlue,
      ),
      body: _players.isEmpty
          ? const Center(
              child: Text(
                "No players available for this team.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  color: lightBlue.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lightBlue,
                      backgroundImage: NetworkImage(player.profileImage),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Error loading image: $exception');
                      },
                      child: player.profileImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    subtitle: Text(
                      'Role: ${player.role} | Age: ${player.age}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
