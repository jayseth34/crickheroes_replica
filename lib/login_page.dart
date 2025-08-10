import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final _authService = AuthService();

  bool isValid = false;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_validateInput);
  }

  @override
  void dispose() {
    phoneController.removeListener(_validateInput);
    phoneController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = phoneController.text;
    final valid = RegExp(r'^\d{10}$').hasMatch(text);
    if (valid != isValid) {
      setState(() {
        isValid = valid;
      });
    }
  }

  void sendOtp() async {
    if (_formKey.currentState!.validate()) {
      final phone = phoneController.text;

      // Save the mobile number to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', phone);

      final success = true; // Replace with _authService.sendOtp(phone)
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpPage(phone: phone)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: lightBlue.withOpacity(
                    0.7), // Set card background to lightBlue with opacity
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_android,
                          size: 60,
                          color:
                              accentOrange), // Set icon color to accentOrange
                      const SizedBox(height: 16),
                      const Text(
                        "Enter your mobile number",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white), // Set text color to white
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        style: const TextStyle(
                            color: Colors.white), // Input text color
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          labelStyle: const TextStyle(
                              color: Colors.white70), // Label text color
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: lightBlue)), // Border color
                          prefixIcon: const Icon(Icons.phone,
                              color: Colors.white70), // Icon color
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: lightBlue), // Enabled border color
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: accentOrange,
                                width: 2), // Focused border color
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isValid ? sendOtp : null,
                          icon: const Icon(Icons.send,
                              color: Colors.white), // Icon color
                          label: const Text("Send OTP",
                              style:
                                  TextStyle(color: Colors.white)), // Text color
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                accentOrange, // Set button background to accentOrange
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
