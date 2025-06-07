import 'package:flutter/material.dart';
import 'login_page.dart'; // <-- import your login page

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricHeroes Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(), // <-- Set this as the home screen
    );
  }
}
