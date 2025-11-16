import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Android Ad Unit IDs
  static const String _androidBannerAdUnitId =
      'ca-app-pub-7579710244323779/9583261767';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-7579710244323779/6994140338';
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-7579710244323779/3794691228';

  // iOS Ad Unit IDs
  static const String _iosBannerAdUnitId =
      'ca-app-pub-7579710244323779/6122854551';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-7579710244323779/7155351739';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-7579710244323779/7352175745';

  // Platform specific getters
  static String get _bannerAdUnitId {
    return Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
  }

  static String get _interstitialAdUnitId {
    return Platform.isAndroid
        ? _androidInterstitialAdUnitId
        : _iosInterstitialAdUnitId;
  }

  static String get _rewardedAdUnitId {
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

  // Banner Ad
  static BannerAd createBannerAd({BannerAdListener? listener}) {
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
          print('Interstitial ad loaded successfully');

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
          _isInterstitialLoading = false;
          _isInterstitialAdReady = false;
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
  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
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
            print('Reward fallback triggered after ad dismissed.');
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
