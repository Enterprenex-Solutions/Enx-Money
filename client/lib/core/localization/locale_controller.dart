import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static final LocaleController _instance = LocaleController._internal();
  factory LocaleController() => _instance;
  static LocaleController get instance => _instance;
  LocaleController._internal();

  static const String _prefKey = 'selected_app_language_name';

  static const List<String> languageNames = [
    'English (US)',
    'Hindi (हिंदी)',
    'Telugu (తెలుగు)',
    'Tamil (தமிழ்)',
    'Kannada (ಕನ್ನಡ)',
    'Malayalam (മലയാളം)',
    'Marathi (मराठी)',
    'Bengali (বাংলা)',
    'Gujarati (ગુજરાતી)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Odia (ଓଡ଼ିଆ)',
    'Urdu (اردو)',
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('hi', 'IN'),
    Locale('te', 'IN'),
    Locale('ta', 'IN'),
    Locale('kn', 'IN'),
    Locale('ml', 'IN'),
    Locale('mr', 'IN'),
    Locale('bn', 'IN'),
    Locale('gu', 'IN'),
    Locale('pa', 'IN'),
    Locale('or', 'IN'),
    Locale('ur', 'PK'),
  ];

  Locale _locale = const Locale('en', 'US');
  String _currentLanguageName = 'English (US)';

  Locale get locale => _locale;
  String get currentLanguageName => _currentLanguageName;
  bool get isRtl => _locale.languageCode == 'ur';
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Map display name to Locale
  static Locale getLocaleFromName(String name) {
    if (name.contains('Hindi') || name.contains('हिंदी')) {
      return const Locale('hi', 'IN');
    } else if (name.contains('Telugu') || name.contains('తెలుగు')) {
      return const Locale('te', 'IN');
    } else if (name.contains('Tamil') || name.contains('தமிழ்')) {
      return const Locale('ta', 'IN');
    } else if (name.contains('Kannada') || name.contains('ಕನ್ನಡ')) {
      return const Locale('kn', 'IN');
    } else if (name.contains('Malayalam') || name.contains('മലയാളം')) {
      return const Locale('ml', 'IN');
    } else if (name.contains('Marathi') || name.contains('मराठी')) {
      return const Locale('mr', 'IN');
    } else if (name.contains('Bengali') || name.contains('বাংলা')) {
      return const Locale('bn', 'IN');
    } else if (name.contains('Gujarati') || name.contains('ગુજરાતી')) {
      return const Locale('gu', 'IN');
    } else if (name.contains('Punjabi') || name.contains('ਪੰਜਾਬੀ')) {
      return const Locale('pa', 'IN');
    } else if (name.contains('Odia') || name.contains('ଓଡ଼ିଆ')) {
      return const Locale('or', 'IN');
    } else if (name.contains('Urdu') || name.contains('اردو')) {
      return const Locale('ur', 'PK');
    }
    return const Locale('en', 'US');
  }

  /// Map Locale to display name
  static String getNameFromLocale(Locale loc) {
    switch (loc.languageCode) {
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'te':
        return 'Telugu (తెలుగు)';
      case 'ta':
        return 'Tamil (தமிழ்)';
      case 'kn':
        return 'Kannada (ಕನ್ನಡ)';
      case 'ml':
        return 'Malayalam (മലയാളം)';
      case 'mr':
        return 'Marathi (मराठी)';
      case 'bn':
        return 'Bengali (বাংলা)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      case 'pa':
        return 'Punjabi (ਪੰਜਾਬੀ)';
      case 'or':
        return 'Odia (ଓଡ଼ିଆ)';
      case 'ur':
        return 'Urdu (اردو)';
      case 'en':
      default:
        return 'English (US)';
    }
  }

  /// Initialize and load saved language from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefKey);
      if (savedName != null && savedName.isNotEmpty) {
        _currentLanguageName = savedName;
        _locale = getLocaleFromName(savedName);
      } else {
        _locale = const Locale('en', 'US');
        _currentLanguageName = 'English (US)';
      }
    } catch (_) {
      _locale = const Locale('en', 'US');
      _currentLanguageName = 'English (US)';
    }
    notifyListeners();
  }

  /// Update language and notify all listening widgets for instant app rebuild
  Future<void> setLanguage(String name) async {
    _currentLanguageName = name;
    _locale = getLocaleFromName(name);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, name);
    } catch (_) {}

    notifyListeners();
  }

  /// Update locale directly
  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    _currentLanguageName = getNameFromLocale(loc);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _currentLanguageName);
    } catch (_) {}

    notifyListeners();
  }
}
