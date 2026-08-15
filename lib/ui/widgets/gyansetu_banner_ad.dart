import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GyansetuBannerAd extends StatefulWidget {
  const GyansetuBannerAd({super.key});

  @override
  State<GyansetuBannerAd> createState() => _GyansetuBannerAdState();
}

class _GyansetuBannerAdState extends State<GyansetuBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 🎯 GYANSETU BANNER AD ID
  final String adUnitId = 'ca-app-pub-2076369951420983/7204049624';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SafeArea(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    // Jab tak ad load ho rahi hai, thodi jagah reserve rakhega taaki UI jump na kare
    return const SizedBox(height: 50);
  }
}