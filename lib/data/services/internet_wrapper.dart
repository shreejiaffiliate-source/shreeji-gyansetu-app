import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';

enum AppErrorType { none, noInternet, serverDown }

class InternetWrapper extends StatefulWidget {
  final Widget child;
  const InternetWrapper({super.key, required this.child});

  @override
  State<InternetWrapper> createState() => _InternetWrapperState();
}

class _InternetWrapperState extends State<InternetWrapper> {
  bool _isServerDown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // ✅ Har 10 second mein ye khud check karega ki server zinda hai ya nahi
    _timer = Timer.periodic(const Duration(seconds: 10), (t) => _checkServer());
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      // 💡 Tip: Sirf '/' check karne ki jagah '/api/home/' ya koi light endpoint check karo
      final response = await http.get(Uri.parse(ApiEndpoints.baseUrl))
          .timeout(const Duration(seconds: 5));

      debugPrint("DEBUG: Server Check Status: ${response.statusCode}");

      // Agar humein server se koi bhi response mil raha hai (below 500), toh server chalu hai
      if (response.statusCode < 500) {
        if (_isServerDown) setState(() => _isServerDown = false);
      } else {
        if (!_isServerDown) setState(() => _isServerDown = true);
      }
    } catch (e) {
      debugPrint("DEBUG: Server Check Error: $e");
      // Agar connection refuse ho raha hai (Server band hai)
      if (!_isServerDown) setState(() => _isServerDown = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ... (Enum aur class definition same rahegi) ...

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connectivityResult = snapshot.data;

        // 1. Internet Check
        if (connectivityResult == null || connectivityResult.contains(ConnectivityResult.none)) {
          return ErrorDisplayScreen(
            errorType: AppErrorType.noInternet,
            onRetry: _checkServer, // ✅ Function pass kiya
          );
        }

        // 2. Server Check
        if (_isServerDown) {
          return ErrorDisplayScreen(
            errorType: AppErrorType.serverDown,
            onRetry: _checkServer, // ✅ Function pass kiya
          );
        }

        // 3. Normal App
        return widget.child;
      },
    );
  }
}

// --- Error Display Screen (Iska logic ekdum perfect hai) ---
class ErrorDisplayScreen extends StatelessWidget {
  final AppErrorType errorType;
  final VoidCallback onRetry;

  const ErrorDisplayScreen({
    super.key,
    required this.errorType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    bool isNoInternet = errorType == AppErrorType.noInternet;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNoInternet ? Icons.wifi_off_rounded : Icons.dns_rounded,
              size: 120,
              color: isNoInternet ? Colors.grey : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            const Text("OOPS!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
                isNoInternet ? "NO INTERNET" : "SERVER DOWN",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onRetry, // ✅ Ab ye sahi trigger hoga
              child: const Text("TRY AGAIN", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}