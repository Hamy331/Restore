import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Resolve fonts through package_config so tests work with any pub-cache path.
Future<void> loadTestFonts() async {
  final config = File('.dart_tool/package_config.json').absolute.uri;
  final packages =
      (jsonDecode(await File.fromUri(config).readAsString())
              as Map<String, dynamic>)['packages']
          as List;
  Uri packageRoot(String name) {
    final root =
        packages.cast<Map<String, dynamic>>().firstWhere(
              (package) => package['name'] == name,
            )['rootUri']
            as String;
    return config.resolve(root.endsWith('/') ? root : '$root/');
  }

  Future<void> load(String family, List<Uri> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        File.fromUri(file).readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  }

  final materialFonts = packageRoot(
    'flutter',
  ).resolve('../../bin/cache/artifacts/material_fonts/');
  await load('Roboto', [
    for (final weight in [
      'Regular',
      'Medium',
      'Bold',
      'Black',
      'Light',
      'Thin',
    ])
      materialFonts.resolve('Roboto-$weight.ttf'),
  ]);
  final lucide = packageRoot('lucide_icons_flutter').resolve('assets/');
  await load('packages/lucide_icons_flutter/Lucide', [
    lucide.resolve('lucide.ttf'),
  ]);
  for (final weight in [100, 200, 300, 400, 500, 600]) {
    await load('packages/lucide_icons_flutter/Lucide$weight', [
      lucide.resolve('build_font/LucideVariable-w$weight.ttf'),
    ]);
  }
}
