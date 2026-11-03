import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/language/language_bloc.dart';
import '../../../core/blocs/language/language_event.dart';
import '../../../core/blocs/language/language_state.dart';
import '../../../l10n/app_localizations.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LanguageBloc, LanguageState>(
        listener: (context, state) {
          if (state.saveFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.settingsLanguageError,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final l = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(title: Text(l.settingsPageTitle)),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        l.settingsLanguage,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l.settingsLanguageHint),
                      const SizedBox(height: 20),
                      for (final entry in const {
                        'vi': 'Tiếng Việt',
                        'en': 'English',
                      }.entries)
                        ListTile(
                          title: Text(entry.value),
                          selected: state.locale.languageCode == entry.key,
                          trailing: state.locale.languageCode == entry.key
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => context.read<LanguageBloc>().add(
                            ChangeLanguage(Locale(entry.key)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
