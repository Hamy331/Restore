import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

import '../models/policy_content.dart';

/// Trang Chính sách Restore (mở từ chân trang và menu Tài khoản).
/// `?section=<id>` cuộn thẳng tới mục, VD `/policies?section=reviews`.
class PoliciesView extends StatefulWidget {
  const PoliciesView({super.key, this.section});

  static const path = '/policies';
  static String sectionPath(String id) => '$path?section=$id';

  final String? section;

  @override
  State<PoliciesView> createState() => _PoliciesViewState();
}

class _PoliciesViewState extends State<PoliciesView> {
  final _keys = {for (final s in policySections) s.id: GlobalKey()};

  @override
  void initState() {
    super.initState();
    final id = widget.section;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jump(id));
    }
  }

  @override
  void didUpdateWidget(PoliciesView old) {
    super.didUpdateWidget(old);
    final id = widget.section;
    if (id != null && id != old.section) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jump(id));
    }
  }

  void _jump(String id) {
    final target = _keys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(PolicyText text) => text.of(vi);
    final title = vi ? 'Chính sách Restore' : 'Restore policies';

    return Scaffold(
      backgroundColor: AppColors.fill,
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: needsBackButton(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Intro(
                  title: title,
                  subtitle: vi
                      ? 'Quy định trả giá, đánh giá và mua bán an toàn trên Restore.'
                      : 'How offers, reviews and safe trading work on Restore.',
                  effective:
                      '${vi ? 'Hiệu lực từ' : 'Effective'} ${t(policyEffectiveDate)}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in policySections)
                      ActionChip(
                        avatar: Icon(s.icon, size: 16),
                        label: Text(t(s.title)),
                        onPressed: () => _jump(s.id),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final s in policySections) ...[
                  _SectionCard(key: _keys[s.id], section: s, vi: vi),
                  const SizedBox(height: 12),
                ],
                _Contact(vi: vi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.title,
    required this.subtitle,
    required this.effective,
  });
  final String title;
  final String subtitle;
  final String effective;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              AppIcons.calendar,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              effective,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.section, required this.vi});
  final PolicySection section;
  final bool vi;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.actionSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                section.icon,
                size: 18,
                color: AppColors.actionPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title.of(vi),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        for (final block in section.blocks) ...[
          const SizedBox(height: 12),
          _Block(block: block, vi: vi),
        ],
      ],
    ),
  );
}

const _body = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: AppColors.textPrimary,
);

class _Block extends StatelessWidget {
  const _Block({required this.block, required this.vi});
  final PolicyBlock block;
  final bool vi;

  @override
  Widget build(BuildContext context) => switch (block) {
    PolicyParagraph(:final text) => Text(text.of(vi), style: _body),
    PolicySubheading(:final text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text.of(vi),
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    ),
    PolicyBullets(:final items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 10, left: 2),
                  child: CircleAvatar(
                    radius: 2.5,
                    backgroundColor: AppColors.textSecondary,
                  ),
                ),
                Expanded(child: Text(item.of(vi), style: _body)),
              ],
            ),
          ),
      ],
    ),
    PolicyTable(:final header, :final rows) => _PolicyTableView(
      header: header,
      rows: rows,
      vi: vi,
    ),
    PolicySteps(:final steps) => Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(
            index: i + 1,
            title: steps[i].$1.of(vi),
            body: steps[i].$2.of(vi),
            last: i == steps.length - 1,
          ),
      ],
    ),
    PolicyNote(:final text, :final warning) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningBg : AppColors.infoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? AppIcons.warning : AppIcons.info,
            size: 18,
            color: warning ? AppColors.warning : AppColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text.of(vi), style: _body)),
        ],
      ),
    ),
  };
}

class _PolicyTableView extends StatelessWidget {
  const _PolicyTableView({
    required this.header,
    required this.rows,
    required this.vi,
  });
  final (PolicyText, PolicyText) header;
  final List<(PolicyText, PolicyText)> rows;
  final bool vi;

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: _body.copyWith(
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
        border: TableBorder.all(color: AppColors.border),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.fill),
            children: [
              cell(header.$1.of(vi), bold: true),
              cell(header.$2.of(vi), bold: true),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [cell(row.$1.of(vi), bold: true), cell(row.$2.of(vi))],
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.body,
    required this.last,
  });
  final int index;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.actionPrimary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAction,
                ),
              ),
            ),
            if (!last)
              const Expanded(
                child: VerticalDivider(width: 2, color: AppColors.border),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: _body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Contact extends StatelessWidget {
  const _Contact({required this.vi});
  final bool vi;

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        const Icon(AppIcons.help, color: AppColors.actionPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            vi
                ? 'Còn thắc mắc hoặc muốn khiếu nại một quyết định kiểm duyệt?'
                : 'Questions, or want to appeal a moderation decision?',
            style: _body,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => context.push('/support'),
          child: Text(vi ? 'Trung tâm trợ giúp' : 'Help centre'),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}
