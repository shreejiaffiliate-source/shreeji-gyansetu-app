import 'package:flutter/material.dart';

class StatusErrorScreen extends StatelessWidget {
  final bool isServerError; // true = Server Down, false = No Internet
  final VoidCallback onRetry;

  const StatusErrorScreen({
    super.key,
    required this.isServerError,
    required this.onRetry
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Condition based Image
            isServerError
                ? const Icon(Icons.dns_outlined, size: 120, color: Colors.redAccent) // Server Icon
                : Image.asset('lib/assets/images/no_internet_dog.png', height: 250), // Dog Image

            const SizedBox(height: 40),

            // Condition based Text
            Text(
              isServerError ? "OOPS! SERVER ERROR" : "OOPS! NO INTERNET",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              isServerError
                  ? "Our server is under maintenance. Please try again later."
                  : "Please check your network connection.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("TRY AGAIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}