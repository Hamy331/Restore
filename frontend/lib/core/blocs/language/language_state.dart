import 'package:flutter/material.dart';

class LanguageState {
  final Locale locale;
  final bool saveFailed;
  LanguageState(this.locale, {this.saveFailed = false});
}
