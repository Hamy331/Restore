import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  //  Default Language: English
  LanguageBloc() : super(LanguageState(const Locale('en'))) {
    on<ChangeLanguage>((event, emit) {
      emit(LanguageState(event.locale));
    });
  }
}
