---
name: tekartik-build-node-npm
description: >-
  Use when a Dart build script must manage the node packages of a repository
  or run CI on a node-enabled Dart package with tekartik_build_node:
  isNodePackageRoot, recursiveNodePackagePath,
  recursiveNodePackageJsonRelativePaths, nodePackageNpmInstall,
  recursiveNodePackageNpmInstall, nodePackageGetNpmDependencies,
  NodePackageNpmDependencies, nodePackageNpmUpdateLatest,
  recursiveNodePackageNpmUpdateLatest, nodePackageRunCi and
  NodePackageRunCiOptions (package:tekartik_build_node/package.dart).
---

# npm packages and node CI (tekartik_build_node)

Besides compiling Dart to node, `tekartik_build_node` drives `npm` over a
whole repository (find every `package.json`, install, update to latest) and
runs the CI of a node-enabled Dart package (`dart test -p node` on top of
`dev_build`'s `packageRunCi`).

## Guidelines

* Dev-time tool, `node`/`npm` must be on the `PATH`. Git dependency:
  ```yaml
  dev_dependencies:
    tekartik_build_node:
      git:
        url: https://github.com/tekartik/build_node.dart
        path: packages/build_node
  ```
* Imports: the npm helpers are in
  `package:tekartik_build_node/build_node.dart` (same import as the build
  helpers of
  [../tekartik-build-node-build/SKILL.md](../tekartik-build-node-build/SKILL.md));
  the CI entry point is in `package:tekartik_build_node/package.dart`.
* Discovery: `isNodePackageRoot(path)` is a sync `bool` (a `package.json`
  exists there). `recursiveNodePackagePath(List<String> dirs)` returns every
  node package found under `dirs`, the dirs themselves included, sorted and
  deduplicated by absolute path; it skips `node_modules`, `build` and hidden
  folders but **not** `deploy` (a `deploy/functions` cloud-function package is
  found). It throws an `ArgumentError` when an entry of `dirs` is not a
  directory. `recursiveNodePackageJsonRelativePaths(dir)` gives the same
  result as `<relative path>/package.json` strings, handy for a report or a
  `git add` list.
* Install: `nodePackageNpmInstall(path, {bool force = false})` runs
  `npm install` in `path` only when it is a node package **and**
  `node_modules` is missing (pass `force: true` to always run it).
  `recursiveNodePackageNpmInstall(dirs, {force})` does that for every package
  found, logging one `# npm install <path>` or `# skipping <path>` line per
  package. Both are no-ops (with a log) when nothing is found.
* Update: `nodePackageGetNpmDependencies(path)` reads `package.json` and
  returns a `NodePackageNpmDependencies` with `dependencies`,
  `devDependencies` (`List<String>` of names) and `isEmpty`. Only registry
  dependencies are listed: `file:`, `link:`, `portal:`, `workspace:`, `git:`,
  `git+`, `github:`, `http:`, `https:`, `npm:` specs and `user/repo`
  shorthands are excluded because they cannot be bumped to `@latest`.
  `nodePackageNpmUpdateLatest(path)` runs `npm install --save <name>@latest`
  and `npm install --save-dev <name>@latest` for them (so `package.json` and
  `package-lock.json` are rewritten); `recursiveNodePackageNpmUpdateLatest(
  dirs)` does it for the whole tree. Review/commit the resulting diff.
* CI: `nodePackageRunCi(String path, [NodePackageRunCiOptions? options])`
  first runs `dev_build`'s `packageRunCi` with `noTest: true` (pub get,
  format, analyze), then, when a `test/` folder exists, runs
  `dart test -p vm,node` — adding `node` only when `node` is on the `PATH`,
  after an `npm install` and an offline `dart pub get` workaround. It returns
  early (doing nothing more) when `tool/run_ci_override.dart` exists, and
  skips the tests when the package sdk constraint does not match the running
  Dart version (message on stderr).
* `NodePackageRunCiOptions({noNodeTest, noVmTest, noAnalyze, noFormat,
  noPubGet, noNpmInstall, noOverride})` — all `bool` defaulting to `false`,
  all named, passed as the second **positional** argument of
  `nodePackageRunCi`. Use `noNodeTest: true` on a machine without node,
  `noOverride: true` to ignore `tool/run_ci_override.dart`.
* These helpers shell out with `package:process_run`: a failing `npm`/`dart`
  command throws and should be left to propagate from a `tool/` script.

## Examples

### tool/run_ci.dart — CI of the current package

```dart
import 'dart:io';

import 'package:tekartik_build_node/package.dart';

Future<void> main(List<String> args) async {
  var path = args.isNotEmpty ? args.first : Directory.current.path;
  await nodePackageRunCi(path);
}
```

### CI without the node tests (no node on this machine)

```dart
import 'package:tekartik_build_node/package.dart';

Future<void> main() async {
  await nodePackageRunCi(
    '.',
    NodePackageRunCiOptions(noNodeTest: true, noFormat: true),
  );
}
```

### tool/npm_install.dart — install every node package of the repo

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main(List<String> args) async {
  await recursiveNodePackageNpmInstall(args.isEmpty ? ['.'] : args);
}
```

### List the node packages and their npm dependencies

```dart
import 'dart:io';

import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  for (var path in await recursiveNodePackagePath(['.'])) {
    var dependencies = await nodePackageGetNpmDependencies(path);
    stdout.writeln('$path: $dependencies');
  }
  stdout.writeln(await recursiveNodePackageJsonRelativePaths('.'));
}
```

### tool/npm_update.dart — bump every npm dependency to latest

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await recursiveNodePackageNpmUpdateLatest(['.']);
  // package.json files are modified, review the diff before committing.
}
```

## Common mistakes

* Expecting `nodePackageNpmInstall` to refresh an existing install: without
  `force: true` it is skipped when `node_modules` exists.
* Expecting local/git npm dependencies to be updated by
  `nodePackageNpmUpdateLatest`: they are filtered out on purpose.
* Passing `NodePackageRunCiOptions` as a named argument: the second parameter
  of `nodePackageRunCi` is positional.
* Wondering why `nodePackageRunCi` does nothing: a `tool/run_ci_override.dart`
  file takes over (use `noOverride: true`), or the sdk constraint does not
  match.
* Importing `build_node.dart` for `nodePackageRunCi`: it is exported by
  `package.dart`.
