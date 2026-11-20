import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';

class ListingPartnerBadge extends StatelessWidget {
  const ListingPartnerBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFFE8590C),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_user, color: Colors.white, size: 11),
        const SizedBox(width: 2),
        Text(
          AppLocalizations.of(context)!.followingHubPartner,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class ListingCardTitle extends StatelessWidget {
  final String title;
  final bool isPartner;
  final TextStyle style;

  const ListingCardTitle({
    super.key,
    required this.title,
    required this.isPartner,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        if (isPartner)
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: ListingPartnerBadge(),
            ),
          ),
        TextSpan(text: title),
      ],
    ),
    style: style,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}
