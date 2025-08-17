import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // Import convert for JSON decoding

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({required this.phone, Key? key}) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();

  bool isValid = false;
  String _storedMobileNumber =
      ''; // New state variable to hold the retrieved number

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    otpController.addListener(_validateInput);
    _loadStoredMobileNumber(); // Load the mobile number from storage
  }

  @override
  void dispose() {
    otpController.removeListener(_validateInput);
    otpController.dispose();
    super.dispose();
  }

  // A new function to load the mobile number from shared preferences
  void _loadStoredMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNumber = prefs.getString('mobileNumber');
    if (storedNumber != null) {
      setState(() {
        _storedMobileNumber = storedNumber;
      });
    }
  }

  void _validateInput() {
    final text = otpController.text;
    final valid = RegExp(r'^\d{4,6}$').hasMatch(text);
    if (valid != isValid) {
      setState(() {
        isValid = valid;
      });
    }
  }

  // New async function to handle the API call and data storage
  Future<void> _loginWithApi() async {
    // NOTE: For a real app, you would use a base URL and add a dynamic number.
    // Here, we use the provided number for demonstration.
    // The API URL is hardcoded as per the request, but in a real scenario,
    // you would use the _storedMobileNumber state variable.
    final String apiUrl =
        'https://sportsdecor.somee.com/api/Auth/loginWithMob?mobNo=$_storedMobileNumber';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // API call was successful. Decode the JSON response.
        final responseData = json.decode(response.body);
        final int? playerId = responseData['id'];

        if (playerId != null) {
          // Store the retrieved 'id' in shared preferences as 'playerId'.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('playerId', playerId);
          print('Player ID ($playerId) stored successfully!');

          // Navigate to the next page after successful data storage.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          print('Error: "id" field not found in API response.');
        }
      } else {
        // Handle cases where the server responded with an error status code.
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any network or other errors during the API call.
      print('An error occurred during API call: $e');
    }
  }

  void verifyOtp() {
    if (_formKey.currentState!.validate()) {
      // Call the new API function instead of navigating directly.
      _loginWithApi();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                color: lightBlue.withOpacity(
                    0.7), // Set card background to lightBlue with opacity
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sms,
                          size: 60,
                          color:
                              accentOrange), // Set icon color to accentOrange
                      const SizedBox(height: 16),
                      // Display the stored mobile number if available
                      Text(
                        "OTP sent to ${_storedMobileNumber.isNotEmpty ? _storedMobileNumber : widget.phone}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white, // Set text color to white
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                            color: Colors.white), // Input text color
                        decoration: InputDecoration(
                          labelText: "Enter OTP",
                          labelStyle: const TextStyle(
                              color: Colors.white70), // Label text color
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock,
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
                            return 'Please enter the OTP';
                          } else if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
                            return 'OTP must be 4 to 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isValid ? verifyOtp : null,
                          icon: const Icon(Icons.check,
                              color: Colors.white), // Icon color
                          label: const Text("Verify OTP",
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
