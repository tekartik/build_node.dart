Build node helpers

## Setup

In `pubspec.yaml`, add the following `dev_dependencies`:

```yaml
dev_dependencies:
  # needed node dependencies
  build_runner:
  build_web_compilers:
  tekartik_build_node:
    git:
      url: https://github.com/tekartik/build_node.dart
      path: packages/build_node
      ref: dart2_3
```

Create `build.yaml` with at least:

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
          # enforce dart2js compiler
          compiler: dart2js
```

In `analysis_options.yaml` add:

```
analyzer:
  exclude:
   - build/**
```
## Usage

Create your main entry point in `node\main.dart`

```dart
void main() {
  print('Hello world');
}
```

## Build

Create `tool\build_node.dart`:

```dart
import 'package:tekartik_build_node/build_node.dart';

Future main() async {
  await nodeBuild();
}
```

## Run

Create `tool\run_node.dart`:

```dart
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
node build/node/main.dart.js
  ''');
}
```
