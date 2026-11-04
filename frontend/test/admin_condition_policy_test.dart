import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/views/listing_details/widgets/listing_condition_section.dart';

void main() {
  testWidgets('posting only offers conditions allowed by administrator', (tester) async {
    ListingCondition? selected;
    await tester.pumpWidget(MaterialApp(
      locale:const Locale('vi'),supportedLocales:AppLocalizations.supportedLocales,
      localizationsDelegates:AppLocalizations.localizationsDelegates,
      home:Scaffold(body:ListingConditionSection(selected:ListingCondition.usedGood,
        loadConditions:()async=>{ListingCondition.newItem:'Mới được phép'},onSelected:(value)=>selected=value)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mới được phép'),findsOneWidget);
    expect(find.byType(InkWell),findsOneWidget);
    await tester.tap(find.text('Mới được phép'));
    expect(selected,ListingCondition.newItem);
  });
}
