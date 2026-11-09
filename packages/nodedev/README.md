# tekartik_nodedev

`nodedev`, a command line tool to build, watch and run a Dart package compiled
for node.js, and to run `npm` over every `package.json` of a tree. It wraps
[tekartik_build_node](../build_node/README.md) (dart2js plus the node
preamble). Dev-time tool on the Dart VM (Linux, macOS, Windows) with `dart`,
`node` and `npm` on the `PATH`. Not on pub.dev.

## Getting started

```bash
dart pub global activate -s git https://github.com/tekartik/build_node.dart --git-path packages/nodedev
nodedev --help
```

Or per project, as a git dev dependency and `dart run tekartik_nodedev:nodedev`:

```yaml
dev_dependencies:
  tekartik_nodedev:
    git:
      url: https://github.com/tekartik/build_node.dart
      path: packages/nodedev
```

The package to build has its entry point in `node/main.dart`, `build_runner`
and `build_web_compilers` in its `dev_dependencies` and a `build.yaml` (see
the [build_node README](../build_node/README.md)). Then, in that package:

```bash
nodedev bar      # build node/main.dart, then node build/node/main.dart.js
```

## Commands

`--path <dir>` (default `.`) selects the package.

| Command | Does |
|---|---|
| `build [--debug]` | `build_runner build` of `node/` to `build/node/*.dart.js`, then the node preamble |
| `watch` | `build_runner watch` (debug), preamble added when the watcher exits |
| `run [--app node/main.dart]` | `node build/<app>.js` (`node/main.dart`, else `bin/main.dart`) |
| `bar [--debug] [--app ...]` | build, then run |
| `npm-install [--no-recursive] [--force]` | `npm install` in every folder holding a `package.json` (skipped when `node_modules` exists, unless `--force`) |
| `npm-list-path [--no-recursive]` | the relative path of every `package.json` |
| `npm-update-latest [--no-recursive]` | `npm install <name>@latest` for every registry dependency (not git, file or url ones) |

## Common pitfalls

* A failing `dart`, `node` or `npm` command, or an unknown option, ends
  `nodedev` with a stack trace (exit code 255).
* `run` does not build: use `bar` after a change.
* A plain `dart compile js` output lacks the node preamble (no `require`,
  timers fail); build with `nodedev` or `tekartik_build_node`.

Agent skill: [skills/tekartik-nodedev-cli](skills/tekartik-nodedev-cli/SKILL.md).
