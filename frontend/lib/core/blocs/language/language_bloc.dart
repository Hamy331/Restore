import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_event.dart';
import 'language_state.dart';

class _RestoreLanguage extends LanguageEvent {}

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  //  Default Language: English
  LanguageBloc() : super(LanguageState(const Locale('en'))) {
    on<ChangeLanguage>((event, emit) async {
      if (!['en', 'vi'].contains(event.locale.languageCode)) return;
      _changed = true;
      emit(LanguageState(event.locale));
      try {
        final preferences = await SharedPreferences.getInstance();
        final saved = await preferences.setString(
          'app_language',
          event.locale.languageCode,
        );
        if (!saved) emit(LanguageState(event.locale, saveFailed: true));
      } catch (_) {
        emit(LanguageState(event.locale, saveFailed: true));
      }
    });
    on<_RestoreLanguage>((event, emit) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        final code = preferences.getString('app_language');
        if (!_changed && ['en', 'vi'].contains(code)) {
          emit(LanguageState(Locale(code!)));
        }
      } catch (_) {
        /* Keep the default when storage is unavailable. */
      }
    });
    add(_RestoreLanguage());
  }

  bool _changed = false;
}
