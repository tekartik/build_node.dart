import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'npm_install.dart';

/// Version spec prefixes that don't refer to a published registry version,
/// they must not be replaced by `@latest`.
const _nonRegistryPrefixes = [
  'file:',
  'link:',
  'portal:',
  'workspace:',
  'git:',
  'git+',
  'github:',
  'http:',
  'https:',
  'npm:',
];

/// True if [version] refers to a regular published npm package version.
bool _isRegistryVersion(Object? version) {
  if (version is! String) {
    return false;
  }
  for (var prefix in _nonRegistryPrefixes) {
    if (version.startsWith(prefix)) {
      return false;
    }
  }
  // git shorthand (`user/repo`)
  if (version.contains('/')) {
    return false;
  }
  return true;
}

List<String> _registryDependencyNames(Object? section) {
  if (section is! Map) {
    return <String>[];
  }
  return section.entries
      .where((entry) => _isRegistryVersion(entry.value))
      .map((entry) => entry.key.toString())
      .toList();
}

/// The registry dependencies of a node package, as declared in `package.json`.
class NodePackageNpmDependencies {
  /// Regular dependencies.
  final List<String> dependencies;

  /// Dev dependencies.
  final List<String> devDependencies;

  /// True if there is nothing to update.
  bool get isEmpty => dependencies.isEmpty && devDependencies.isEmpty;

  /// Creates the dependency lists.
  NodePackageNpmDependencies({
    required this.dependencies,
    required this.devDependencies,
  });

  @override
  String toString() =>
      'NodePackageNpmDependencies($dependencies, dev: $devDependencies)';
}

/// Read the registry dependencies declared in the `package.json` of [path].
///
/// Local, git and url dependencies are excluded, they cannot be updated to
/// `@latest`.
Future<NodePackageNpmDependencies> nodePackageGetNpmDependencies(
  String path,
) async {
  if (!isNodePackageRoot(path)) {
    return NodePackageNpmDependencies(
      dependencies: <String>[],
      devDependencies: <String>[],
    );
  }
  var map =
      jsonDecode(await File(join(path, 'package.json')).readAsString()) as Map;
  return NodePackageNpmDependencies(
    dependencies: _registryDependencyNames(map['dependencies']),
    devDependencies: _registryDependencyNames(map['devDependencies']),
  );
}

String _latestArguments(List<String> names) =>
    names.map((name) => shellArgument('$name@latest')).join(' ');

/// Update all the dependencies of the node package in [path] to their latest
/// version, updating `package.json` and installing them.
Future<void> nodePackageNpmUpdateLatest(String path) async {
  var dependencies = await nodePackageGetNpmDependencies(path);
  if (dependencies.isEmpty) {
    return;
  }
  var shell = Shell(workingDirectory: path);
  if (dependencies.dependencies.isNotEmpty) {
    await shell.run(
      'npm install --save ${_latestArguments(dependencies.dependencies)}',
    );
  }
  if (dependencies.devDependencies.isNotEmpty) {
    await shell.run(
      'npm install --save-dev '
      '${_latestArguments(dependencies.devDependencies)}',
    );
  }
}

/// Update to their latest version the dependencies of all the node packages
/// found in [dirs].
Future<void> recursiveNodePackageNpmUpdateLatest(List<String> dirs) async {
  var paths = await recursiveNodePackagePath(dirs);
  if (paths.isEmpty) {
    stdout.writeln('# no node package found in ${dirs.join(', ')}');
    return;
  }
  for (var path in paths) {
    var displayPath = normalize(absolute(path));
    var dependencies = await nodePackageGetNpmDependencies(path);
    if (dependencies.isEmpty) {
      stdout.writeln('# skipping $displayPath (no npm dependency)');
    } else {
      stdout.writeln('# npm update latest $displayPath');
      await nodePackageNpmUpdateLatest(path);
    }
  }
}
