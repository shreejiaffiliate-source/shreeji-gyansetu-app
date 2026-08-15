import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GyansetuNativeAd extends StatefulWidget {
  const GyansetuNativeAd({super.key});

  @override
  State<GyansetuNativeAd> createState() => _GyansetuNativeAdState();
}

class _GyansetuNativeAdState extends State<GyansetuNativeAd> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  // 🎯 GYANSETU NATIVE AD ID
  final String adUnitId = 'ca-app-pub-2076369951420983/3947330890';

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      // 'TemplateType.small' achha lagta hai list items ke beech me
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _nativeAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        height: 100, // Small template ke liye lagbhag itni height theek rehti hai
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ],
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }
    return const SizedBox.shrink(); // Jab tak load na ho, kuch mat dikhao
  }
}