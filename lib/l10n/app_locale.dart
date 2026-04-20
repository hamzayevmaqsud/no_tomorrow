import 'package:flutter/foundation.dart';

enum AppLang { en, ru }

class AppLocale extends ChangeNotifier {
  static final instance = AppLocale._();
  AppLocale._();

  AppLang _lang = AppLang.en;
  AppLang get lang => _lang;
  bool get isRu => _lang == AppLang.ru;

  void setLang(AppLang lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }
}

/// Shorthand: picks English or Russian string based on current locale.
String t(String en, String ru) =>
    AppLocale.instance.lang == AppLang.ru ? ru : en;
