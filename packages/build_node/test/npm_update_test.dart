@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_node/build_node.dart';
import 'package:test/test.dart';

void main() {
  group('npm_update', () {
    late String top;

    Future<NodePackageNpmDependencies> dependenciesOf(
      Map<String, Object?> packageJson,
    ) async {
      File(
        join(top, 'package.json'),
      ).writeAsStringSync(jsonEncode(packageJson));
      return await nodePackageGetNpmDependencies(top);
    }

    setUp(() {
      top = join('.dart_tool', 'tekartik_build_node', 'test', 'npm_update');
      try {
        Directory(top).deleteSync(recursive: true);
      } catch (_) {}
      Directory(top).createSync(recursive: true);
    });

    test('no package.json', () async {
      var dependencies = await nodePackageGetNpmDependencies(top);
      expect(dependencies.isEmpty, isTrue);
    });

    test('no dependencies', () async {
      var dependencies = await dependenciesOf({'name': 'test'});
      expect(dependencies.isEmpty, isTrue);
    });

    test('dependencies and devDependencies', () async {
      var dependencies = await dependenciesOf({
        'dependencies': {
          '@firebase/app': '^0.16.0',
          'firebase-admin': '^14.2.0',
        },
        'devDependencies': {'typescript': '^5.0.0'},
      });
      expect(dependencies.dependencies, ['@firebase/app', 'firebase-admin']);
      expect(dependencies.devDependencies, ['typescript']);
      expect(dependencies.isEmpty, isFalse);
    });

    test('non registry dependencies are ignored', () async {
      var dependencies = await dependenciesOf({
        'dependencies': {
          'firebase-admin': '^14.2.0',
          'local': 'file:../local',
          'linked': 'link:../linked',
          'from_git': 'git+https://github.com/user/repo.git',
          'from_github': 'github:user/repo',
          'shorthand': 'user/repo',
          'from_url': 'https://example.com/pkg.tgz',
          'aliased': 'npm:other@^1.0.0',
          'in_workspace': 'workspace:*',
        },
      });
      expect(dependencies.dependencies, ['firebase-admin']);
    });
  });
}
