---
name: tekartik-nodedev-cli
description: >-
  Use when building, watching or running a Dart package compiled for node.js,
  or running npm over every package.json of a tree, with the nodedev command
  line tool of package:tekartik_nodedev (nodedev build, watch, run, bar,
  npm-install, npm-list-path, npm-update-latest, --path, --debug, --app,
  --recursive, --force, --version, dart pub global activate -s git
  build_node.dart --git-path packages/nodedev, dart run
  tekartik_nodedev:nodedev, embedding MainRunner / run(args) of
  package:tekartik_nodedev/src/runner/main_runner.dart in a tool script).
  Covers install, the node/main.dart and build/node/main.dart.js layout, the
  tekartik_build_node calls behind each command and their failure modes.
---

# nodedev: command line for Dart node.js packages

`tekartik_nodedev` ships one executable, `nodedev`, a `package:args`
`CommandRunner` over `tekartik_build_node`: it compiles a Dart package to
JavaScript for node.js (`build_runner` + `build_web_compilers`, node
preamble prepended), watches it, runs the generated js with `node`, and runs
`npm install` / `npm install <name>@latest` over every `package.json` of a
tree. Dev-time tool, VM only: `dart`, `node` and `npm` must be on the
`PATH`. Git only, not on pub.dev.

```bash
dart pub global activate -s git https://github.com/tekartik/build_node.dart --git-path packages/nodedev
nodedev --path packages/my_node_app bar    # build node/main.dart, then run it with node
```

## Guidelines

### Install and invoke

* Global install: `dart pub global activate -s git
  https://github.com/tekartik/build_node.dart --git-path packages/nodedev`
  (add `--git-ref <branch>` for a branch), then `nodedev` with
  `~/.pub-cache/bin` on the `PATH`. Run the same command again to upgrade.
  From a clone of the repository: `dart pub global activate -s path
  packages/nodedev`.
* Per project: git dev dependency, then `dart run tekartik_nodedev:nodedev
  <command>`:
  ```yaml
  dev_dependencies:
    tekartik_nodedev:
      git:
        url: https://github.com/tekartik/build_node.dart
        path: packages/nodedev
  ```
* `nodedev --version` prints the package version, `nodedev help <command>`
  (or `nodedev <command> --help`) the options of a command.
* `--path <dir>` (default `.`) is the package every command acts on. It is a
  global option but the parser accepts it before or after the command name.
  Paths passed to a command (`--app`) are relative to that package.
* Exit code 0 on success. A failing `dart`, `node` or `npm` command throws
  the `ShellException` of `package:process_run` and nothing catches it: the
  process ends with the stack trace and exit code 255. Same for an unknown
  command (`UsageException`, exit 255 instead of the usual usage message
  and 64).

### build, watch, run, bar

* `build [-d|--debug]` calls `nodePackageBuild(path, debug:)`: in the
  package, `dart run build_runner build --release --output=build/ node
  --delete-conflicting-outputs
  --define=build_web_compilers:entrypoint=compiler=dart2js`, then the
  `node_preamble` is prepended to every `*.dart.js` of `build/node/`
  (`Compiled build/node/main.dart.js <size> bytes`). `--debug` builds with
  `--no-release`.
* Requirements of the package being built: `build_runner` and
  `build_web_compilers` in `dev_dependencies`, the Dart entry points in
  `node/` (`node/main.dart`), and a `build.yaml` at its root:
  ```yaml
  targets:
    $default:
      sources:
        - "$package$"
        - "node/**"
        - "lib/**"
      builders:
        build_web_compilers|entrypoint:
          generate_for:
            - node/**
          options:
            compiler: dart2js
  ```
  Without `build.yaml` the command only prints `Missing 'build.yaml'` on
  stderr, build_runner produces nothing and the command dies with a
  `PathNotFoundException` on `build/node/`.
* `watch` is the same build with `build_runner watch`, always in debug
  (`--no-release`), no flag. It blocks until you stop it (Ctrl-C); the
  preamble is added to the generated files only at that point, so the js
  written while watching is raw dart2js output.
* `run [-a|--app <entry>]` calls `nodePackageRun(path, app:)`: executes
  `node build/<app>.js`. `app` is the Dart entry point relative to the
  package and defaults to `node/main.dart` when it exists, else
  `bin/main.dart`, else `ArgumentError('No app found')`. `run` never
  builds: `build` (or `watch`) first, or `node` fails with "Cannot find
  module".
* `bar [-d] [-a <entry>]` is `build` then `run` with the same options: the
  usual development loop.

### npm-install, npm-list-path, npm-update-latest

* A node package is a folder with a `package.json`. With `--recursive`
  (default) the search starts at `--path`, includes that folder, and skips
  `node_modules`, `build` and hidden folders at every level (`deploy/` is
  entered on purpose: `deploy/functions` is a normal node package).
  `--no-recursive` restricts every npm command to `--path` itself.
* `npm-list-path` prints the path of every `package.json` found, relative
  to `--path`, one per line and sorted (`package.json`,
  `deploy/functions/package.json`). Nothing is printed when there is none.
  Use it to script over the node packages of a repository.
* `npm-install [-f|--force]` runs `npm install` in each node package found
  that has no `node_modules` folder yet, printing `# npm install <path>` or
  `# skipping <path> (node_modules exists)`. `--force` runs it everywhere.
  `# no node package found in <path>` when nothing matches.
* `npm-update-latest` reads `dependencies` and `devDependencies` of each
  `package.json` and runs `npm install --save <name>@latest ...` then
  `npm install --save-dev <name>@latest ...` in the package: `package.json`
  and the lock file are rewritten. Entries whose version is not a registry
  version (`file:`, `link:`, `workspace:`, `git+`, `github:`, urls,
  `user/repo`) are left alone. Packages without npm dependencies are
  skipped with a message. Majors are taken: review the diff afterwards.

### Dart API

* The package has no public library: the runner lives in
  `package:tekartik_nodedev/src/runner/main_runner.dart`, `Future<int>
  run(List<String> args)` returns the exit code and `MainRunner` is the
  `CommandRunner<int>` (its `help` command returns null, mapped to 0).
  `bin/nodedev.dart` is just `exitCode = await run(arguments)`. Importing
  it from another package trips the `implementation_imports` lint;
  acceptable in a repository `tool/` script. Otherwise call the
  `tekartik_build_node` functions the commands wrap (`nodePackageBuild`,
  `nodePackageWatch`, `nodePackageRun`, `recursiveNodePackageNpmInstall`,
  `recursiveNodePackageJsonRelativePaths`,
  `recursiveNodePackageNpmUpdateLatest` from
  `package:tekartik_build_node/build_node.dart`), which is the supported
  API.

## Examples

### Command line

```bash
nodedev --path packages/my_node_app build          # release build
nodedev --path packages/my_node_app build --debug  # --no-release
nodedev --path packages/my_node_app run            # node build/node/main.dart.js
nodedev --path packages/my_node_app run --app node/worker.dart
nodedev --path packages/my_node_app bar -d         # build (debug) and run
nodedev --path packages/my_node_app watch          # rebuild on change, Ctrl-C to stop
nodedev npm-list-path                              # every package.json below .
nodedev npm-install                                # npm install where node_modules is missing
nodedev --path deploy/functions npm-install --no-recursive --force
nodedev npm-update-latest                          # everything to @latest, then review git diff
nodedev help npm-install
```

### tool/nodedev.dart: pin the package path in a repository script

```dart
import 'dart:io';

// ignore: implementation_imports
import 'package:tekartik_nodedev/src/runner/main_runner.dart';

/// `dart run tool/nodedev.dart bar` always works on packages/my_node_app.
Future<void> main(List<String> arguments) async {
  exitCode = await run(['--path', 'packages/my_node_app', ...arguments]);
}
```

### Same steps through the tekartik_build_node API

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  var path = 'packages/my_node_app';
  // nodedev --path packages/my_node_app bar -d
  await nodePackageBuild(path, debug: true);
  await nodePackageRun(path, app: 'node/main.dart');
  // nodedev npm-install
  await recursiveNodePackageNpmInstall(['.']);
  // nodedev npm-list-path
  for (var relativePath in await recursiveNodePackageJsonRelativePaths('.')) {
    print(relativePath);
  }
}
```

### Script over the node packages of a repository

```dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  var results = await Shell(verbose: false).run('nodedev npm-list-path');
  for (var packageJson in results.outLines) {
    // 'package.json' or 'sub/dir/package.json'
    var dir = packageJson == 'package.json'
        ? '.'
        : packageJson.substring(
            0,
            packageJson.length - '/package.json'.length,
          );
    await Shell(workingDirectory: dir).run('npm audit');
  }
}
```

## Common mistakes

* `nodedev run` right after a clone: nothing in `build/`, `node` fails.
  Build first (`bar` does both).
* Running `build` in a package without `build.yaml` or without
  `build_web_compilers`: only a warning, then `PathNotFoundException` on
  `build/node/`.
* Testing the output while `watch` runs: the preamble is only added when
  the watch stops, run `build` for a runnable file.
* `--app build/node/main.dart.js`: `--app` is the Dart entry point
  (`node/main.dart`), the js path is derived from it.
* `npm-install` from a repository root installs every example and deploy
  package: point `--path` at the package or add `--no-recursive`.
* Committing right after `npm-update-latest` without reading the
  `package.json` diff: majors are updated too.

## More

* Package README for the git dependency snippet. The underlying functions
  belong to `tekartik_build_node` (`packages/build_node` of the same
  repository), which documents them.
