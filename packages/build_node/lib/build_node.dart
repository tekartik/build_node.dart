/// Compile Dart to JavaScript for node.js and run it: [nodePackageCompileJs]
/// (`dart compile js`) or [nodePackageBuild] (build_runner) add the node
/// preamble to the output, [nodePackageRun] runs it, [nodePackageRunTest]
/// runs `dart test -p node`; plus the npm helpers ([nodePackageNpmInstall],
/// [recursiveNodePackageNpmUpdateLatest]...).
///
/// Developer tools for the Dart VM, `node` and `npm` must be on the `PATH`.
/// A failing command throws a `ShellException` (process_run).
library;

export 'src/build_node.dart'
    show
        nodeCheck,
        nodePackageCheck,
        nodeBuild,
        nodePackageBuild,
        nodePackageWatch,
        nodePackageRun,
        nodePackageRunTest,
        nodeRunTest,
        nodePackageCompileJs;
export 'src/npm_install.dart'
    show
        isNodePackageRoot,
        recursiveNodePackagePath,
        recursiveNodePackageJsonRelativePaths,
        nodePackageNpmInstall,
        recursiveNodePackageNpmInstall;
export 'src/npm_update.dart'
    show
        NodePackageNpmDependencies,
        nodePackageGetNpmDependencies,
        nodePackageNpmUpdateLatest,
        recursiveNodePackageNpmUpdateLatest;
