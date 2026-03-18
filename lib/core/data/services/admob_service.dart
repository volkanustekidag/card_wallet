import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Real Ad Unit IDs - Android
  static const String _androidBannerAdUnitId =
      'ca-app-pub-7579710244323779/9583261767';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-7579710244323779/6994140338';
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-7579710244323779/3794691228';

  // Real Ad Unit IDs - iOS
  static const String _iosBannerAdUnitId =
      'ca-app-pub-7579710244323779/6122854551';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-7579710244323779/7155351739';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-7579710244323779/7352175745';

  // Test Ad Unit IDs - Android
  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Test Ad Unit IDs - iOS
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // Fallback tracking
  static bool _useTestAdsForBanner = false;
  static bool _useTestAdsForInterstitial = false;
  static bool _useTestAdsForRewarded = false;

  // Platform specific getters
  static String get _bannerAdUnitId {
    if (_useTestAdsForBanner) {
      return Platform.isAndroid
          ? _androidTestBannerAdUnitId
          : _iosTestBannerAdUnitId;
    }
    return Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
  }

  static String get _interstitialAdUnitId {
    if (_useTestAdsForInterstitial) {
      return Platform.isAndroid
          ? _androidTestInterstitialAdUnitId
          : _iosTestInterstitialAdUnitId;
    }
    return Platform.isAndroid
        ? _androidInterstitialAdUnitId
        : _iosInterstitialAdUnitId;
  }

  static String get _rewardedAdUnitId {
    if (_useTestAdsForRewarded) {
      return Platform.isAndroid
          ? _androidTestRewardedAdUnitId
          : _iosTestRewardedAdUnitId;
    }
    return Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId;
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;
  static bool _isInterstitialLoading = false;
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdReady = false;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Enable test ads for fallback
  static void enableTestAdsForBanner() {
    _useTestAdsForBanner = true;
    debugPrint('Enabled test ads for banner');
  }

  static void enableTestAdsForInterstitial() {
    _useTestAdsForInterstitial = true;
    debugPrint('Enabled test ads for interstitial');
  }

  static void enableTestAdsForRewarded() {
    _useTestAdsForRewarded = true;
    debugPrint('Enabled test ads for rewarded');
  }

  // Banner Ad
  static BannerAd createBannerAd({
    BannerAdListener? listener,
    bool useTestAd = false,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ??
          BannerAdListener(
            onAdLoaded: (ad) {},
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
            },
          ),
    );
  }

  // Interstitial Ad
  static int _interstitialLoadAttempts = 0;
  static Future<void> loadInterstitialAd() async {
    if (_isInterstitialLoading) return;
    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _isInterstitialLoading = false;
          _interstitialLoadAttempts = 0;
          debugPrint('Interstitial ad loaded successfully');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              loadInterstitialAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              loadInterstitialAd(); // Yeni reklam yükle
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialLoading = false;
          _isInterstitialAdReady = false;

          // İlk denemede başarısız olursa test reklamını dene
          if (_interstitialLoadAttempts == 0 && !_useTestAdsForInterstitial) {
            debugPrint('Interstitial: Trying fallback to test ad...');
            _interstitialLoadAttempts++;
            enableTestAdsForInterstitial();
            loadInterstitialAd();
          } else {
            _interstitialLoadAttempts = 0;
          }
        },
      ),
    );
  }

  static Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      // Reklam hazır değilse kullanıcıyı bekletmeden yüklemeyi başlat
      unawaited(loadInterstitialAd());
    }
  }

  // Rewarded Ad
  static int _rewardedLoadAttempts = 0;
  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _rewardedLoadAttempts = 0;
          debugPrint('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdReady = false;

          // İlk denemede başarısız olursa test reklamını dene
          if (_rewardedLoadAttempts == 0 && !_useTestAdsForRewarded) {
            debugPrint('Rewarded: Trying fallback to test ad...');
            _rewardedLoadAttempts++;
            enableTestAdsForRewarded();
            loadRewardedAd();
          } else {
            _rewardedLoadAttempts = 0;
          }
        },
      ),
    );
  }

  static Future<bool> showRewardedAd() async {
    try {
      if (!_isRewardedAdReady || _rewardedAd == null) {
        await loadRewardedAd();
      }

      final ad = _rewardedAd;
      if (ad == null) {
        return false;
      }

      bool rewardEarned = false;
      final completer = Completer<bool>();

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;

          // Fallback: bazı cihazlarda onUserEarnedReward tetiklenmediği için
          // reklam tamamlanıp kapandıysa ödülü kazandırıyoruz.
          if (!rewardEarned) {
            debugPrint('Reward fallback triggered after ad dismissed.');
            rewardEarned = true;
          }

          if (!completer.isCompleted) {
            completer.complete(rewardEarned);
          }

          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          loadRewardedAd();
        },
      );

      await ad.show(onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      });

      _rewardedAd = null;
      _isRewardedAdReady = false;

      return await completer.future;
    } catch (e) {
      _rewardedAd = null;
      _isRewardedAdReady = false;
      loadRewardedAd();
      return false;
    }
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
