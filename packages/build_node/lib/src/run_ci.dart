import 'dart:io';

import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:tekartik_build_node/src/node_support.dart';

import 'import.dart';

Future<bool> _isPubPackageRoot(String dir) async {
  try {
    await pathGetPubspecYamlMap(dir);
    return true;
  } catch (_) {
    return false;
  }
}

Future main(List<String> arguments) async {
  String? path;
  if (arguments.isNotEmpty) {
    var firstArg = arguments.first.toString();
    if (await _isPubPackageRoot(firstArg)) {
      path = firstArg;
    }
  }
  path ??= Directory.current.path;
  await nodePackageRunCi(path);
}

Future<List<String>> topLevelDir(String dir) async {
  var list = <String>[];
  await Directory(dir).list(recursive: false).listen((event) {
    if (event is Directory) {
      list.add(basename(event.path));
    }
  }).asFuture();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build'];

List<String> filterDartDirs(List<String> dirs) => dirs.where((element) {
      if (element.startsWith('.')) {
        return false;
      }
      if (_forbiddenDirs.contains(element)) {
        return false;
      }
      return true;
    }).toList(growable: false);

/// Package run options
class NodePackageRunCiOptions {
  final bool noNodeTest;
  final bool noVmTest;
  final bool noPubGet;
  final bool noFormat;
  final bool noAnalyze;
  final bool noNpmInstall;
  final bool noOverride;

  NodePackageRunCiOptions(
      {this.noNodeTest = false,
      this.noVmTest = false,
      this.noAnalyze = false,
      this.noFormat = false,
      this.noPubGet = false,
      this.noNpmInstall = false,
      this.noOverride = false});
}

/// Run basic tests on dart/flutter package
///
/// Dart:
/// ```
/// ```
Future nodePackageRunCi(String path, [NodePackageRunCiOptions? options]) async {
  options ??= NodePackageRunCiOptions();
  await packageRunCi(path,
      options: PackageRunCiOptions(
          noTest: true,
          noPubGet: options.noPubGet,
          noAnalyze: options.noAnalyze,
          noFormat: options.noFormat,
          noOverride: options.noOverride));
  var shell = Shell(workingDirectory: path);

  var pubspecMap = await pathGetPubspecYamlMap(path);

  var sdkBoundaries = pubspecYamlGetSdkBoundaries(pubspecMap)!;

  if (!sdkBoundaries.match(dartVersion)) {
    stderr.writeln('Unsupported sdk boundaries for dart $dartVersion');
    return;
  }

  if (Directory(join(path, 'test')).existsSync()) {
    var platforms = <String>[if (!(options.noVmTest)) 'vm'];

    if (!(options.noNodeTest)) {
      // Add node for standard run test
      // var isNode = pubspecYamlSupportsNode(pubspecMap);
      if (isNodeSupported) {
        platforms.add('node');

        if (!(options.noNpmInstall)) {
          await nodeModulesCheck(path);
        }
        if (!(options.noPubGet)) {
          // Workaround issue about complaining old pubspec on node...
          // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
          await shell.run('''
          # Get dependencies
          dart pub get --offline
    ''');
        }
      }
    }

    if (platforms.isNotEmpty) {
      await shell.run('''
    # Test
    dart test -p ${platforms.join(',')}
    ''');
    }
  }
}
