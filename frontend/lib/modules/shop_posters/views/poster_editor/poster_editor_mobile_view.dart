import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import '../../bloc/poster_editor_cubit.dart';
import '../../models/shop_poster.dart';
import '../../utils/poster_labels.dart';
import 'widgets/poster_image_field.dart';
import 'widgets/poster_link_field.dart';
import 'widgets/poster_schedule_field.dart';
import 'widgets/poster_section.dart';

class PosterEditorMobileView extends StatefulWidget {
  const PosterEditorMobileView({super.key, this.picker});

  final MediaPickerService? picker;

  @override
  State<PosterEditorMobileView> createState() => _PosterEditorMobileViewState();
}

class _PosterEditorMobileViewState extends State<PosterEditorMobileView> {
  late final TextEditingController _title = TextEditingController(
    text: context.read<PosterEditorCubit>().state.title,
  );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final result = await context.read<PosterEditorCubit>().submit();
    if (!mounted || result == null) return;
    switch (result) {
      case PosterSubmitted():
        context.pop(true);
      case PosterSubmitFailed(:final code):
        TSnackBarHelper.showError(context, message: l.posterError(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PosterEditorCubit, PosterEditorState>(
      builder: (context, state) {
        final cubit = context.read<PosterEditorCubit>();
        final running = state.poster?.state == ShopPosterState.running;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(AppIcons.close, color: AppColors.textPrimary),
              onPressed: () => context.pop(false),
            ),
            centerTitle: true,
            title: Text(state.editing ? l.spEditTitle : l.spNewTitle),
          ),
          bottomNavigationBar: AppBottomActionBar(
            key: const ValueKey('poster-submit'),
            primaryLabel: l.spSubmit,
            primaryIcon: AppIcons.send,
            isLoading: state.submitting,
            onPrimary: state.submitting ? null : _submit,
          ),
          body: ListView(
            key: const ValueKey('poster-editor-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (running)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.spEditRunningNote,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              PosterSection(
                title: l.spImage,
                child: PosterImageField(picker: widget.picker),
              ),
              PosterSection(
                child: AppLabeledTextField(
                  key: const ValueKey('poster-title'),
                  label: l.spName,
                  isRequired: true,
                  controller: _title,
                  maxLength: 80,
                  hintText: l.spNameHint,
                  helperText: l.spNameHelper,
                  errorText: state.showErrors && !state.titleValid
                      ? l.spNameRequired
                      : null,
                  onChanged: cubit.setTitle,
                  textInputAction: TextInputAction.done,
                ),
              ),
              PosterSection(title: l.spOpens, child: const PosterLinkField()),
              PosterSection(
                title: l.spSchedule,
                last: true,
                child: const PosterScheduleField(),
              ),
            ],
          ),
        );
      },
    );
  }
}
