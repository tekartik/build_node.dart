---
name: tekartik-build-node-build
description: >-
  Use when compiling a Dart package to JavaScript to run it on node.js with
  tekartik_build_node: nodeBuild, nodePackageBuild, nodePackageCompileJs,
  nodePackageWatch, nodePackageRun, nodeRunTest, nodePackageRunTest,
  nodeCheck, nodePackageCheck, the package:tekartik_build_node/build_node.dart
  import, the node/main.dart entry point, the build.yaml
  build_web_compilers/dart2js setup and the node_preamble added to the
  generated .dart.js files.
---

# Dart to node.js build (tekartik_build_node)

`tekartik_build_node` compiles a Dart package for node.js: it drives
`build_runner`/`build_web_compilers` (or `dart compile js` directly), then
prepends the `node_preamble` to every generated `.dart.js` so the output can
be run with `node`.

## Guidelines

* Dev-time tool, `node` (and `npm` for tests) must be on the `PATH`. Not on
  pub.dev, depend on it with git, together with the build_runner packages it
  drives:
  ```yaml
  dev_dependencies:
    build_runner: ">=2.15.0"
    build_web_compilers: ">=4.4.19"
    tekartik_build_node:
      git:
        url: https://github.com/tekartik/build_node.dart
        path: packages/build_node
  ```
* Layout convention: Dart entry points in `node/` (`node/main.dart`), build
  scripts in `tool/`, output in `build/node/main.dart.js`. `build.yaml` is
  required at the package root (the helpers only warn on stderr when it is
  missing, the build then produces nothing usable):
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
  Also exclude `build/**` in `analysis_options.yaml`, the generated js and its
  companion files should not be analyzed.
* Single import: `package:tekartik_build_node/build_node.dart` (the npm/CI
  helpers are in `package.dart` and in
  [../tekartik-build-node-npm/SKILL.md](../tekartik-build-node-npm/SKILL.md)).
* Two ways to produce the js, both add the node preamble:
  * `nodePackageBuild(path, {String directory = 'node', bool? debug})` (and
    `nodeBuild({directory})` for the current directory) runs
    `dart run build_runner build --release --output=build/ <directory>
    --delete-conflicting-outputs
    --define=build_web_compilers:entrypoint=compiler=dart2js`, then adds the
    preamble to every `*.dart.js` of `build/<directory>`. Use it when the
    package needs builders (generated code, several entry points).
    `debug: true` switches to `--no-release`.
  * `nodePackageCompileJs(path, {String? input, String? output, bool? debug,
    int? optimizationLevel})` calls `dart compile js` directly: no
    build_runner, much faster. `input` defaults to `node/main.dart` and must
    be relative, `output` defaults to `build/<input dir>/<input name>.js`,
    `optimizationLevel` is 0 to 4 (default 2, or 0 with `debug: true`, which
    also passes `--enable-asserts`).
* `nodePackageWatch(path, {directory, debug})` is `nodePackageBuild` with
  `build_runner watch` — keep it running while editing.
* `nodePackageRun(path, {String? app, String? jsFile})` runs
  `node <file>`: `jsFile` as is, or `build/$app.js` where `app` defaults to
  `node/main.dart` if it exists, else `bin/main.dart`, else it throws an
  `ArgumentError`. Build (or compile) first, it does not build.
* Tests: `nodePackageRunTest(path, {List<String>? testFiles})` (and
  `nodeRunTest()` for the current directory) runs `npm install` when needed
  then `dart test -p node` (optionally on the given files). Node tests need
  the `test` package and a working `node`.
* `nodeCheck()` / `nodePackageCheck(path)` only verify that `build.yaml`
  exists (warning on stderr); the `nodePackage*` build/test helpers already
  call the check, and `nodeCheck()` runs at most once per process.
* Every helper takes a package `path` (`'.'` for the current one) and returns
  a `Future`; a failing command throws a `ShellException` from
  `package:process_run`, which is what a `tool/` script should let propagate
  so the exit code is non zero.
* The generated js targets node, not the browser: `dart:io` is not available,
  use `package:node_interop`-style bindings (or the tekartik node packages),
  and keep the preamble — running a raw dart2js output with `node` fails
  without it.

## Examples

### tool/build_node.dart — build with build_runner

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await nodePackageBuild('.');
  // Compiled ./build/node/main.dart.js 34689 bytes
}
```

### tool/compile_js_and_run_node.dart — compile and run

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await nodePackageCompileJs('.'); // node/main.dart -> build/node/main.dart.js
  await nodePackageRun('.');
}
```

### Debug build of another entry point, then run it

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await nodePackageCompileJs(
    'packages/my_node_app',
    input: 'node/loop.dart',
    debug: true, // -O0 --enable-asserts
  );
  await nodePackageRun(
    'packages/my_node_app',
    jsFile: 'build/node/loop.dart.js',
  );
}
```

### tool/watch_node.dart — rebuild on change

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await nodePackageWatch('.', debug: true);
}
```

### tool/run_node_test.dart — run the tests on node

```dart
import 'package:tekartik_build_node/build_node.dart';

Future<void> main() async {
  await nodePackageRunTest('.', testFiles: ['test/simple_test.dart']);
}
```

## Common mistakes

* No `build.yaml` (or one that does not `generate_for: node/**`): the build
  prints a warning and no `.dart.js` is produced.
* Running the dart2js output directly without the preamble step (i.e. calling
  `dart compile js` by hand instead of `nodePackageCompileJs`).
* Calling `nodePackageRun` before building, or on a package whose entry point
  is neither `node/main.dart` nor `bin/main.dart` without passing `app`/
  `jsFile`.
* Passing an absolute `input` to `nodePackageCompileJs` (it throws an
  `ArgumentError` when `output` is not given).
* Using `dart:io` in the node entry point.
