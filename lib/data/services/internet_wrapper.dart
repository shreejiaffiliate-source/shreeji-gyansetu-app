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
    _timer = Timer.periodic(
        const Duration(seconds: 30), (t) => _checkServer());
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      // 💡 Tip: Sirf '/' check karne ki jagah '/api/home/' ya koi light endpoint check karo
      final response = await http.get(Uri.parse(ApiEndpoints.health))
          .timeout(const Duration(seconds: 5));

      debugPrint("DEBUG: Server Check Status: ${response.statusCode}");

      // Agar humein server se koi bhi response mil raha hai (below 500), toh server chalu hai
      if (response.statusCode == 200) {
        if (_isServerDown) {
          setState(() {
            _isServerDown = false;
          });
        }
      } else {
        if (!_isServerDown) {
          setState(() {
            _isServerDown = true;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        setState(() {
          _isServerDown = false;
        });
      }
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
        // ✅ FIX: Jab tak pehla connectivity data nahi milta, tab tak loading dikhao
        // Isse wo "No Internet" wali screen jhat se nahi aayegi
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          if (snapshot.hasError) {
            return widget.child;
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF003366),
              ),
            ),
          );
        }

        final connectivityResult = snapshot.data;

        // 1. Internet Check
        // ConnectivityResult.none ka matlab hai internet bilkul nahi hai
        if (connectivityResult == null ||
            connectivityResult.contains(ConnectivityResult.none)) {
          return ErrorDisplayScreen(
            errorType: AppErrorType.noInternet,
              onRetry: () async {
                await _checkServer();
              }
          );
        }

        // 2. Server Check
        // Agar internet hai par backend server response nahi de raha
        if (_isServerDown) {
          return ErrorDisplayScreen(
            errorType: AppErrorType.serverDown,
              onRetry: () async {
                await _checkServer();
              }
          );
        }

        // 3. Normal App
        // Jab sab sahi ho tab asli UI dikhao
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