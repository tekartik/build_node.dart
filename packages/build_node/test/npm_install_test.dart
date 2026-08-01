@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_node/build_node.dart';
import 'package:test/test.dart';

void main() {
  group('npm_install', () {
    late String top;

    void addNodePackage(String relative) {
      var dir = join(top, relative);
      Directory(dir).createSync(recursive: true);
      File(join(dir, 'package.json')).writeAsStringSync('{}');
    }

    setUp(() {
      top = join('.dart_tool', 'tekartik_build_node', 'test', 'npm_install');
      try {
        Directory(top).deleteSync(recursive: true);
      } catch (_) {}
      Directory(top).createSync(recursive: true);
    });

    test('isNodePackageRoot', () {
      expect(isNodePackageRoot(top), isFalse);
      addNodePackage('.');
      expect(isNodePackageRoot(top), isTrue);
    });

    test('recursiveNodePackagePath', () async {
      addNodePackage('.');
      addNodePackage('sub');
      addNodePackage(join('sub', 'deep'));
      // gcf like layout, deploy is not ignored
      addNodePackage(join('deploy', 'functions'));
      // Ignored
      addNodePackage('node_modules');
      addNodePackage(join('sub', 'node_modules', 'pkg'));
      addNodePackage('build');
      addNodePackage('.hidden');

      var paths = await recursiveNodePackagePath([top]);
      expect(paths.map((path) => relative(path, from: top)).toList(), [
        '.',
        join('deploy', 'functions'),
        'sub',
        join('sub', 'deep'),
      ]);
    });

    test('recursiveNodePackageJsonRelativePaths', () async {
      addNodePackage('.');
      addNodePackage('sub');
      addNodePackage(join('deploy', 'functions'));
      addNodePackage('node_modules');

      expect(await recursiveNodePackageJsonRelativePaths(top), [
        'package.json',
        join('deploy', 'functions', 'package.json'),
        join('sub', 'package.json'),
      ]);
    });

    test('recursiveNodePackagePath none', () async {
      Directory(join(top, 'sub')).createSync(recursive: true);
      expect(await recursiveNodePackagePath([top]), isEmpty);
    });
  });
}
