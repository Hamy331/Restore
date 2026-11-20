import 'package:restore/modules/feeds/repositories/feeds_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/feeds/bloc/feeds/feeds_cubit.dart';
import 'package:restore/modules/feeds/models/feed_models.dart';
import 'package:restore/modules/feeds/views/feeds/feeds_view.dart';
import 'package:restore/modules/feeds/widgets/feed_post_card.dart';

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
  testWidgets('desktop feed uses the width of its content area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeFeedsRepository();
    final width = ValueNotifier<double>(508);
    addTearDown(width.dispose);
    await tester.pumpWidget(
      host(
        const Locale('en'),
        Center(
          child: ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (_, value, child) => SizedBox(width: value, child: child),
            child: FeedsView(repository: repository),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('For you'), findsOneWidget);
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Write a post'), findsNothing);
    expect(tester.takeException(), isNull);

    width.value = 1440;
    await tester.pumpAndSettle();
    expect(find.text('Write a post'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search submits, follows the selected tab and clears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeFeedsRepository()..pageSize = 1;
    repository.rows[0]['text'] = 'Old bicycle';
    repository.rows[1]['text'] = 'Samsung phone';
    repository.rows[1]['isFollowingAuthor'] = true;
    await tester.pumpWidget(
      host(const Locale('en'), FeedsView(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' samsung ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Samsung phone'), findsOneWidget);
    expect(find.text('Old bicycle'), findsNothing);
    for (final width in [1366.0, 375.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.controller!.text.trim(), 'samsung');
      expect(find.text('Samsung phone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Samsung phone'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no match');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('No matching posts found.'), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();
    expect(find.text('Samsung phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'search pagination keeps its filter and refresh restarts the result set',
    () async {
      final repository = FakeFeedsRepository()..pageSize = 1;
      repository.rows[0]['text'] = 'Samsung phone';
      repository.rows[1]['text'] = 'Samsung tablet';
      repository.rows.add({...fakePost('Other'), 'text': 'Bicycle'});
      final cubit = FeedsCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.search(' samsung ');
      await cubit.loadMore();
      expect(cubit.state.posts.map((p) => p.text), [
        'Samsung phone',
        'Samsung tablet',
      ]);
      await cubit.load();
      expect(cubit.state.searchQuery, 'samsung');
      expect(cubit.state.posts.length, 1);
    },
  );

  for (final width in [360.0, 768.0]) {
    testWidgets('comment threads and hearts fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeFeedsRepository();
      await tester.pumpWidget(
        host(const Locale('en'), FeedsView(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Comments').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'First comment');
      await tester.pump();
      await tester.tap(find.byTooltip('Send comment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reply').first);
      await tester.pumpAndSettle();
      expect(find.text('Replying to Me'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'A reply');
      await tester.pump();
      await tester.tap(find.byTooltip('Send comment'));
      await tester.pumpAndSettle();
      expect(find.text('A reply'), findsOneWidget);
      expect(
        repository.replies.values.first.last.parentId,
        repository.replies.values.first.first.id,
      );
      await tester.tap(find.byTooltip('Like').last);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.tap(find.text('Hide replies'));
      await tester.pumpAndSettle();
      expect(find.text('A reply'), findsNothing);
      await tester.tap(find.text('View 1 replies'));
      await tester.pumpAndSettle();
      expect(find.text('A reply'), findsOneWidget);
      expect(find.byTooltip('Add photo'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'image-only replies preserve their image and parent after liking',
    () async {
      final repository = FakeFeedsRepository();
      final cubit = FeedsCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.load();
      final post = cubit.state.posts.first;
      expect(
        await cubit.comment(post, '', image: 'picked.jpg', parentId: 'parent'),
        isTrue,
      );
      final comment = cubit.state.comments[post.id]!.single;
      expect(comment.parentId, 'parent');
      expect(comment.image, isNotNull);
      await cubit.toggleCommentLike(post.id, comment);
      expect(cubit.state.comments[post.id]!.single.image, comment.image);
      expect(cubit.state.comments[post.id]!.single.parentId, 'parent');
    },
  );
  test('API feed handles validation, likes, follows and publishing', () async {
    final cubit = FeedsCubit(repository: FakeFeedsRepository());
    await cubit.load();
    final post = cubit.state.posts.first;
    expect(await cubit.publish(' ', null), false);
    expect(await cubit.comment(post, ' '), false);
    await cubit.toggleLike(post);
    expect(cubit.find(post.id)!.likes, 25);
    await cubit.toggleLike(cubit.find(post.id)!);
    expect(cubit.find(post.id)!.likes, 24);
    await cubit.load(following: true);
    expect(cubit.state.posts, isEmpty);
    await cubit.load(following: false);
    await cubit.toggleFollow(post.authorId);
    await cubit.load(following: true);
    expect(cubit.state.posts.length, 1);
    await cubit.load(following: false);
    expect(await cubit.publish('New post', null), true);
    expect(cubit.state.posts.first.text, 'New post');
    await cubit.load();
    expect(cubit.state.posts.first.text, 'New post');
    await cubit.close();
  });

  test('like is optimistic and reverts when the request fails', () async {
    final repository = FakeFeedsRepository()..failLike = true;
    final cubit = FeedsCubit(repository: repository);
    await cubit.load();
    final post = cubit.state.posts.first;
    final request = cubit.toggleLike(post);
    expect(cubit.find(post.id)!.liked, isTrue);
    expect(cubit.find(post.id)!.likes, 25);
    await request;
    expect(cubit.find(post.id)!.liked, isFalse);
    expect(cubit.find(post.id)!.likes, 24);
    await cubit.close();
  });

  test(
    'unfollowing in the following tab removes posts without reloading',
    () async {
      final repository = FakeFeedsRepository();
      final cubit = FeedsCubit(repository: repository);
      await cubit.load(following: false);
      await cubit.toggleFollow('Minh Anh');
      await cubit.load(following: true);
      expect(cubit.state.posts.length, 1);
      final loads = repository.feedLoads;
      await cubit.toggleFollow('Minh Anh');
      expect(cubit.state.posts, isEmpty);
      expect(repository.feedLoads, loads);
      await cubit.close();
    },
  );

  test('publishing stays on the current tab', () async {
    final cubit = FeedsCubit(repository: FakeFeedsRepository());
    await cubit.loadMe();
    expect(cubit.state.me?.name, 'Me');
    await cubit.load(following: true);
    expect(await cubit.publish('Hello', null), true);
    expect(cubit.state.onlyFollowing, isTrue);
    expect(cubit.state.posts.where((p) => p.text == 'Hello'), isEmpty);
    await cubit.close();
  });

  test('profile feed only loads the author and deletes own posts', () async {
    final repository = FakeFeedsRepository();
    final cubit = FeedsCubit(repository: repository, authorId: 'me');
    await cubit.load();
    expect(cubit.state.posts, isEmpty);
    expect(await cubit.publish('Mine', null), true);
    final mine = cubit.state.posts.single;
    expect(mine.isMine, isTrue);
    expect(await cubit.delete(mine), isTrue);
    expect(cubit.state.posts, isEmpty);
    expect(repository.rows.where((r) => r['id'] == mine.id), isEmpty);
    await cubit.close();
  });

  test('reports go through the moderation endpoint', () async {
    final repository = FakeFeedsRepository();
    final cubit = FeedsCubit(repository: repository);
    await cubit.load();
    expect(await cubit.report(cubit.state.posts.first, 'Spam'), isTrue);
    expect(repository.reports, ['Minh Anh:Spam']);
    await cubit.close();
  });

  test('load more failure stops auto paging until retried', () async {
    final repository = FakeFeedsRepository()..pageSize = 1;
    final cubit = FeedsCubit(repository: repository);
    await cubit.load();
    repository.failNextPage = true;
    await cubit.loadMore();
    expect(cubit.state.loadMoreFailed, isTrue);
    await cubit.loadMore();
    expect(cubit.state.posts.length, 1);
    await cubit.loadMore(retry: true);
    expect(cubit.state.loadMoreFailed, isFalse);
    expect(cubit.state.posts.length, 2);
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
        expect(tester.takeException(), isNull);
        final menu = find
            .ancestor(
              of: find.byIcon(AppIcons.moreHorizontal).first,
              matching: find.byType(IconButton),
            )
            .first;
        if (width < 1024) {
          expect(
            tester.getRect(menu).right,
            inInclusiveRange(width - 12, width - 4),
          );
          expect(tester.getCenter(find.text('Feeds')).dx, width / 2);
        } else {
          expect(tester.getRect(menu).right, lessThan(width));
        }
        // Desktop: menu trái cũng có mục "Đang theo dõi", tab nằm sau cùng
        await tester.tap(
          find.text(code == 'vi' ? 'Đang theo dõi' : 'Following').last,
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
    await tester.pump();
    expect(find.text('17/2,000'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField).last, 'Nice!');
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

  testWidgets('closing a dirty draft asks before discarding', (tester) async {
    await tester.pumpWidget(
      host(const Locale('en'), FeedsView(repository: FakeFeedsRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share a find or a story…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard post?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsNothing);
    expect(find.text('Share a find or a story…'), findsOneWidget);
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
    expect(find.text('Report post'), findsOneWidget);
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Hoàng Huy'), findsNothing);
  });

  testWidgets('own post menu deletes after confirmation', (tester) async {
    final cubit = FeedsCubit(repository: FakeFeedsRepository());
    addTearDown(cubit.close);
    final post = FeedPost.fromJson({...fakePost('A'), 'isMine': true});
    await tester.pumpWidget(
      host(const Locale('en'), FeedPostCard(cubit: cubit, post: post)),
    );
    await tester.tap(find.byIcon(AppIcons.moreHorizontal));
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsNothing);
    expect(find.text('Report post'), findsNothing);
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
    expect(
      find.text("Delete this post? This can't be undone."),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a notification link opens the post comments', (tester) async {
    await tester.pumpWidget(
      host(
        const Locale('en'),
        FeedsView(repository: FakeFeedsRepository(), openPostId: 'Minh Anh'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('a deleted post from a notification shows a notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Locale('en'),
        FeedsView(repository: FakeFeedsRepository(), openPostId: 'gone'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.text('This post is no longer available.'), findsOneWidget);
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

class FakeFeedsRepository implements FeedsRepository {
  final rows = [fakePost('Minh Anh'), fakePost('Hoàng Huy')];
  final Map<String, List<FeedComment>> replies = {};
  final List<String> reports = [];
  bool failLike = false, failNextPage = false;
  int feedLoads = 0, pageSize = 20, _created = 0;

  @override
  Future<FeedUser> me() async =>
      const FeedUser(id: 'me', name: 'Me', avatarUrl: null);

  @override
  Future<FeedPage<FeedPost>> posts({
    bool following = false,
    String? authorId,
    String? cursor,
    String? query,
  }) async {
    if (cursor != null && failNextPage) {
      failNextPage = false;
      throw Exception('offline');
    }
    feedLoads++;
    final matching = rows
        .where(
          (p) =>
              (!following || p['isFollowingAuthor'] == true) &&
              (authorId == null || p['author']['id'] == authorId) &&
              (query == null ||
                  (p['text'] as String).toLowerCase().contains(
                    query.toLowerCase(),
                  )),
        )
        .toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, matching.length);
    return FeedPage([
      for (final row in matching.sublist(start, end)) FeedPost.fromJson(row),
    ], end < matching.length ? '$end' : null);
  }

  @override
  Future<FeedPost> post(String id) async =>
      FeedPost.fromJson(rows.firstWhere((r) => r['id'] == id));

  @override
  Future<FeedPost> publish(String text, String? imageUrl) async {
    final row = {
      ...fakePost('me'),
      'id': 'new-${_created++}',
      'text': text,
      'isMine': true,
      'likeCount': 0,
    };
    rows.insert(0, row);
    return FeedPost.fromJson(row);
  }

  @override
  Future<void> delete(String postId) async =>
      rows.removeWhere((r) => r['id'] == postId);

  @override
  Future<FeedPage<FeedComment>> comments(
    String postId, {
    String? cursor,
  }) async => FeedPage(replies[postId] ?? [], null);

  @override
  Future<FeedComment> comment(
    String postId,
    String text, {
    String? imageUrl,
    String? parentId,
  }) async {
    final created = FeedComment(
      id: 'c${replies.values.fold<int>(0, (total, items) => total + items.length)}',
      author: const FeedUser(id: 'me', name: 'Me'),
      text: text,
      image: imageUrl,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    (replies[postId] ??= []).add(created);
    return created;
  }

  @override
  Future<({bool liked, int likes})> likePost(String id, bool value) async {
    if (failLike) throw Exception('offline');
    return (liked: value, likes: value ? 25 : 24);
  }

  @override
  Future<({bool liked, int likes})> likeComment(String id, bool value) async =>
      (liked: value, likes: value ? 1 : 0);

  @override
  Future<void> follow(String id, bool value) async {
    for (final p in rows) {
      if (p['author']['id'] == id) p['isFollowingAuthor'] = value;
    }
  }

  @override
  Future<void> report(FeedPost post, String reason) async =>
      reports.add('${post.authorId}:$reason');

  @override
  Future<String> upload(String path) async => 'https://example.test/$path';
}
