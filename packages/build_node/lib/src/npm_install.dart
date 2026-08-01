import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// Directories never entered when looking for node packages.
///
/// `deploy` is *not* blacklisted, a `deploy/functions` package (gcf) is a
/// regular node package that needs its own `npm install`.
const _blackListedDirs = ['node_modules', 'build'];

bool _isToBeIgnored(String baseName) {
  if (baseName.startsWith('.')) {
    return true;
  }
  return _blackListedDirs.contains(baseName);
}

/// True if [path] is a node package root (i.e. contains a `package.json`)
bool isNodePackageRoot(String path) =>
    File(join(path, 'package.json')).existsSync();

/// Find recursively all node packages (i.e. folder containing a `package.json`)
/// in [dirs], including [dirs] themselves.
///
/// `node_modules`, `build` and hidden folders are skipped.
Future<List<String>> recursiveNodePackagePath(List<String> dirs) async {
  var list = <String>[];
  var absolutes = <String>{};

  void add(String dir) {
    var absolutePath = normalize(absolute(dir));
    if (absolutes.add(absolutePath)) {
      list.add(dir);
    }
  }

  Future<void> handleDir(String dir) async {
    if (isNodePackageRoot(dir)) {
      add(dir);
    }
    await for (var entity in Directory(dir).list(followLinks: false)) {
      if (entity is Directory) {
        var subDir = entity.path;
        if (!_isToBeIgnored(basename(subDir))) {
          await handleDir(subDir);
        }
      }
    }
  }

  for (var dir in dirs) {
    if (!FileSystemEntity.isDirectorySync(dir)) {
      throw ArgumentError('$dir not a directory');
    }
    await handleDir(dir);
  }
  list.sort();
  return list;
}

/// Find recursively all `package.json` files in [dir], returning their path
/// relative to [dir].
Future<List<String>> recursiveNodePackageJsonRelativePaths(String dir) async {
  var paths = await recursiveNodePackagePath([dir]);
  return paths
      .map((path) => normalize(join(relative(path, from: dir), 'package.json')))
      .toList();
}

/// True if `npm install` should be run in [path].
bool _npmInstallNeeded(String path, {required bool force}) =>
    isNodePackageRoot(path) &&
    (force || !(Directory(join(path, 'node_modules')).existsSync()));

/// Run `npm install` in [path] if it is a node package (i.e. it contains a
/// `package.json`).
///
/// Unless [force] is true, this is a no-op if `node_modules` already exists.
Future<void> nodePackageNpmInstall(String path, {bool force = false}) async {
  if (_npmInstallNeeded(path, force: force)) {
    await Shell(workingDirectory: path).run('npm install');
  }
}

/// Run `npm install` recursively on all node packages found in [dirs].
///
/// Unless [force] is true, packages with an existing `node_modules` folder are
/// skipped.
Future<void> recursiveNodePackageNpmInstall(
  List<String> dirs, {
  bool force = false,
}) async {
  var paths = await recursiveNodePackagePath(dirs);
  if (paths.isEmpty) {
    stdout.writeln('# no node package found in ${dirs.join(', ')}');
    return;
  }
  for (var path in paths) {
    var displayPath = normalize(absolute(path));
    if (_npmInstallNeeded(path, force: force)) {
      stdout.writeln('# npm install $displayPath');
      await nodePackageNpmInstall(path, force: force);
    } else {
      stdout.writeln('# skipping $displayPath (node_modules exists)');
    }
  }
}
