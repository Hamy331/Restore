import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';

Map<String, String> reviewTags(AppLocalizations l) => {
  'friendly': l.tradeFriendly,
  'punctual': l.tradePunctual,
  'reliable': l.tradeReliable,
  'accurate': l.tradeAccurate,
  'quality': l.tradeQuality,
  'fairPrice': l.tradeFairPrice,
};

class ReviewStars extends StatelessWidget {
  const ReviewStars(this.value, {super.key, this.onChanged, this.size = 18});
  final double value, size;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        if (onChanged != null)
          IconButton(
            tooltip: '$i / 5',
            onPressed: () => onChanged!(i),
            icon: _star(i),
          )
        else
          _star(i),
    ],
  );
  Widget _star(int i) => Icon(
    value >= i
        ? Icons.star_rounded
        : value >= i - .5
        ? Icons.star_half_rounded
        : Icons.star_border_rounded,
    size: size,
    color: const Color(0xffffb300),
  );
}
