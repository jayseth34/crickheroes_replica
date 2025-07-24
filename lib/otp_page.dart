import 'package:flutter/material.dart';
import 'home_page.dart';

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

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    otpController.addListener(_validateInput);
  }

  @override
  void dispose() {
    otpController.removeListener(_validateInput);
    otpController.dispose();
    super.dispose();
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

  void verifyOtp() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
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
                      Text(
                        "OTP sent to ${widget.phone}",
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
