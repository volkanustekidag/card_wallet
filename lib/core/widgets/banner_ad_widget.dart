import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallet_app/core/data/services/admob_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasTriedFallback = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd({bool useTestAd = false}) {
    _bannerAd = AdMobService.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
          if (useTestAd) {
            print('Banner: Fallback test ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();

          // iOS'ta gerçek reklam yüklenemezse test reklamını dene
          if (!_hasTriedFallback && !useTestAd) {
            print('Banner: Trying fallback to test ad...');
            _hasTriedFallback = true;
            AdMobService.enableTestAdsForBanner();
            _loadAd(useTestAd: true);
          } else {
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
              });
            }
          }
        },
      ),
      useTestAd: useTestAd,
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
