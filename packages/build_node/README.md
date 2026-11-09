# tekartik_build_node

Build helpers to run Dart on node.js: compile a Dart entry point to
JavaScript with dart2js and add the node preamble (without it, the
generated js fails on node at its first timer), run it, run the
`dart test -p node` tests, run CI with the node tests, and manage the
`npm` packages of a repository.

These are developer tools (a `tool/` script or a test), run on the Dart VM
(Linux, macOS, Windows) with `node` and `npm` on the `PATH`. Not on pub.dev,
use a git dependency.

## Getting started

```yaml
dev_dependencies:
  # needed by nodePackageBuild (not by nodePackageCompileJs)
  build_runner: ">=2.15.0"
  build_web_compilers: ">=4.4.19"
  tekartik_build_node:
    git:
      url: https://github.com/tekartik/build_node.dart
      path: packages/build_node
```

The node entry point is `node/main.dart`:

```dart
void main() {
  print('Hello node');
}
```

Compile and run it from `tool/run_node.dart` (`dart run tool/run_node.dart`):

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  // dart compile js node/main.dart -> build/node/main.dart.js + preamble
  await nodePackageCompileJs('.');
  // node build/node/main.dart.js
  await nodePackageRun('.');
}
```

Exclude the output from the analysis in `analysis_options.yaml`:

```yaml
analyzer:
  exclude:
    - build/**
```

## Which helper

| Helper | Does |
|---|---|
| `nodePackageCompileJs(path, {input, output, debug, optimizationLevel})` | `dart compile js` (default `node/main.dart` to `build/node/main.dart.js`), then the preamble. Fast, no build_runner |
| `nodePackageBuild(path, {directory, debug})`, `nodeBuild()` | `build_runner build` of `node/` (needs `build.yaml`, below), then the preamble on every `build/node/*.dart.js` |
| `nodePackageRun(path, {app, jsFile})` | `node build/node/main.dart.js` (or `bin/main.dart`, `app`, `jsFile`), does not build |
| `nodePackageRunTest(path, {testFiles})`, `nodeRunTest()` | `npm install` when needed, then `dart test -p node` |
| `nodePackageRunCi(path, [options])` (`package.dart`) | dev_build `packageRunCi` (pub get, format, analyze), then `dart test -p vm,node` |
| `recursiveNodePackageNpmInstall(dirs)`, `recursiveNodePackageNpmUpdateLatest(dirs)` | `npm install` / dependencies to `@latest` in every `package.json` folder |

Every helper throws the `ShellException` (process_run) of a failing
command: let it through a `tool/` script so the exit code is not 0.

`build.yaml` for `nodePackageBuild`:

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

## Common mistakes

* Running a js compiled by hand (`dart compile js`) with node: no preamble,
  `self` is undefined at the first `Timer`. Use `nodePackageCompileJs`.
* `nodePackageWatch` (build_runner watch) does not add the preamble yet:
  the preamble step only runs when the watcher exits. Compile with
  `nodePackageCompileJs` or `nodePackageBuild` before running the output.
* `dart:io` in the node code: it is not available on node, use node
  bindings (the tekartik `*_node` packages).
* `Random.secure()` needs node 19 or later (a global `crypto`).
* Expecting `nodePackageRunCi` to fail when the sdk constraint does not
  match the running Dart: it prints "Unsupported sdk boundaries" and skips
  the tests (exit code 0). A `tool/run_ci_override.dart` file also replaces
  the node part.

The package skills (`skills/`) have more examples.
