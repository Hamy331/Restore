import 'package:restore/modules/feeds/repositories/feeds_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/feeds/bloc/feeds_cubit.dart';
import 'package:restore/modules/feeds/views/feeds_view.dart';
import 'package:restore/modules/feeds/views/widgets/feed_post_card.dart';
Widget host(Locale locale, Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  test('API feed handles validation, likes, follows and publishing', () async {
    final cubit = FeedsCubit(repository: FakeFeedsRepository());
    await cubit.load();
    final post = cubit.state.posts.first;
    expect(await cubit.publish(' ', null), false);
    expect(await cubit.comment(post, ' '), false);
    await cubit.toggleLike(post);
    expect(post.likes, 25);
    await cubit.toggleLike(post);
    expect(post.likes, 24);
    await cubit.load(following: true);
    expect(cubit.state.posts, isEmpty);
    await cubit.load(following: false);
    await cubit.toggleFollow(post.authorId);
    await cubit.load(following: true);
    expect(cubit.state.posts.length, 1);
    expect(await cubit.publish('New post', null), true);
    expect(cubit.state.posts.first.text, 'New post');
    await cubit.load();
    expect(cubit.state.posts.first.text, 'New post');
    await cubit.close();
  });
  for (final code in ['vi', 'en']) {
    for (final width in [360.0, 375.0, 412.0, 768.0, 1024.0]) {
      testWidgets('feed fits $width in $code', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          host(Locale(code), FeedsView(repository: FakeFeedsRepository())),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(code == 'vi' ? 'Dành cho bạn' : 'For you'),
          findsOneWidget,
        );
        expect(
          find.text(code == 'vi' ? 'Feeds' : 'Dành cho bạn'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        final menu = find.ancestor(of: find.byIcon(AppIcons.moreHorizontal).first, matching: find.byType(IconButton)).first;
        final contentRight = width <= 680 ? width : (width + 680) / 2;
        expect(
          tester.getRect(menu).right,
          inInclusiveRange(contentRight - 12, contentRight - 4),
        );
        await tester.tap(
          find.text(code == 'vi' ? 'Đang theo dõi' : 'Following'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Minh Anh'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('post and comment use repository with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      host(const Locale('en'), FeedsView(repository: FakeFeedsRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share a find or a story…'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Post'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'My pre-loved find');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('My pre-loved find'), findsOneWidget);
    await tester.tap(find.byTooltip('Comments').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nice!');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();
    expect(find.text('Nice!'), findsOneWidget);
    await tester.tap(find.byTooltip('Like').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unlike'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post has no copy action and follows from the menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      host(const Locale('en'), FeedsView(repository: FakeFeedsRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.copy), findsNothing);
    await tester.tap(find.byIcon(AppIcons.moreHorizontal).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Hoàng Huy'), findsNothing);
  });

  testWidgets('listing post without a photo renders', (tester) async {
    final cubit = FeedsCubit(repository: FakeFeedsRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      host(
        const Locale('en'),
        FeedPostCard(
          cubit: cubit,
          post: FeedPost.fromJson({
            ...fakePost('A'),
            'listing': {'id': 'l1', 'title': 'Lamp', 'price': '1000'},
          }),
        ),
      ),
    );
    expect(find.text('Lamp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> fakePost(String name) => {
  'id': name,
  'author': {'id': name, 'fullName': name, 'avatarUrl': null},
  'text': 'Story',
  'createdAt': DateTime.now().toUtc().toIso8601String(),
  'imageUrl': null,
  'listing': null,
  'likeCount': 24,
  'commentCount': 0,
  'likedByMe': false,
  'isMine': false,
  'isFollowingAuthor': false,
};

class FakeFeedsRepository extends FeedsRepository {
  final rows = [fakePost('Minh Anh'), fakePost('Hoàng Huy')];
  final Map<String, List<Map<String, dynamic>>> replies = {};
  @override
  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    if (path.endsWith('/comments'))
      return {'items': replies[path.split('/')[2]] ?? [], 'nextCursor': null};
    return {
      'items': rows
          .where(
            (p) =>
                query?['tab'] != 'following' || p['isFollowingAuthor'] == true,
          )
          .toList(),
      'nextCursor': null,
    };
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    if (path.endsWith('/comments')) {
      final id = path.split('/')[2];
      (replies[id] ??= []).add({
        'id': 'c1',
        'author': {'id': 'me', 'fullName': 'Me', 'avatarUrl': null},
        'text': data['text'],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'likeCount': 0,
        'likedByMe': false,
      });
      return replies[id]!.last;
    } else
      rows.insert(0, {...fakePost('me'), 'text': data['text'], 'isMine': true});
    return {};
  }

  @override
  Future<Map<String, dynamic>> like(String path, bool value) async => {
    'likedByMe': value,
    'likeCount': path.startsWith('/feeds/')
        ? (value ? 25 : 24)
        : (value ? 1 : 0),
  };
  @override
  Future<void> follow(String id, bool value) async {
    for (final p in rows) {
      if (p['author']['id'] == id) p['isFollowingAuthor'] = value;
    }
  }
}
