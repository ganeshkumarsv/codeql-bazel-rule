load("@io_bazel_rules_go//go:def.bzl", "GoArchive", "GoPath", "go_context", "go_library", "go_path")

def codeql_scan_test_impl(ctx):
    go_ctx = go_context(ctx)
    toolchain = ctx.toolchains["//bazel_rule:toolchain_type"].codeql_info
    codeql = toolchain.executable
    gopath = ctx.attr.go_path[GoPath]
    arc = ctx.attr.library[GoArchive]
    testdriver = ctx.actions.declare_file(ctx.attr.name + ".executable")
    ctx.actions.write(testdriver, """#!/usr/bin/env bash
    set -o pipefail
    set -o errexit
    set -o nounset
    set -o allexport
    PATH=${{PWD}}/{GOSDK}:${{PATH}}
    QUERY_LOCATION=${{PWD}}/external/*/qlpacks/codeql/go-queries/*/codeql-suites/go-security-and-quality.qls
    GOLANGCI_LINT_CACHE=${{TEST_TMPDIR}}/golangci-lint-cache
    GOCACHE=${{TEST_TMPDIR}}/gocache
    GOMODCACHE=${{TEST_TMPDIR}}/gomodcache
    GOPATH=${{TEST_TMPDIR}}/gopath
    cp -RL {SOURCE_GOPATH} ${{GOPATH}}
    CODEQL_BIN="${{PWD}}/{BIN}"
    DB_SUFFIX=$(openssl rand -hex 4 | tr -d '[:punct:]' | cut -c1-5)
    OUTPUT_PATH="${{TEST_UNDECLARED_OUTPUTS_DIR}}/query-results.sarif"
    GOMAXPROCS=2 ${{CODEQL_BIN}} database create /tmp/dd-source_${{DB_SUFFIX}}.codeql --source-root={PKG} --language=go
    ${{CODEQL_BIN}} database analyze /tmp/dd-source_${{DB_SUFFIX}}.codeql $QUERY_LOCATION --sarif-add-query-help --quiet --format=sarifv2.1.0 --output=${{OUTPUT_PATH}}
    # Overwrite (--overwrite) flag might fail sometimes when overwriting a db. Hence Cleaning up CodeQL database after the analysis.
    rm -rf /tmp/dd-source_${{DB_SUFFIX}}.codeql
    """.format(
        SOURCE_GOPATH = gopath.gopath,
        BIN = codeql.files.to_list()[0].path,
        PKG = arc.data.importpath,
        GOSDK = go_ctx.go.path[:-1 - len(go_ctx.go.basename)],
    ), is_executable = True)
    return [
        DefaultInfo(
            executable = testdriver,
            runfiles = ctx.runfiles(
                [go_ctx.go, gopath.gopath_file],
                transitive_files = depset(ctx.files.srcs, transitive = [
                    codeql.files,
                    depset(toolchain.exporter),
                ]),
            ),
        ),
    ]

codeql_scan_test = rule(
    # Rename executable to test for make it a test rule
    test = True,
    implementation = codeql_scan_test_impl,
    toolchains = [
        "@io_bazel_rules_go//go:toolchain",
        "//bazel_rule:toolchain_type",
    ],
    attrs = {
        "library": attr.label(
            providers = [GoArchive],
            mandatory = True,
        ),
        "go_path": attr.label(
            providers = [GoPath],
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = True),
        "_go_context_data": attr.label(
            default = "@io_bazel_rules_go//:go_context_data",
        ),
    },
)

def codeql_scan(
        name,
        srcs,
        importpath,
        embedsrcs = None,
        config = None,
        **kwargs):
    """Performs CodeQL Scan in Golang source files using [codeql-cli](https://codeql.github.com/docs/codeql-cli/getting-started-with-the-codeql-cli/)
    Args:
        name: A unique name for this rule.
        codeql_root: Source root of the app for which CodeQL scan is performed.
    """

    libname = name + ".library"

    go_library(
        name = libname,
        srcs = srcs,
        embedsrcs = embedsrcs,
        importpath = importpath,
        testonly = True,
    )

    go_path(
        name = name + ".go_path",
        include_data = False,
        testonly = True,
    )

    codeql_scan_test(
        name = name,
        library = libname,
        srcs = srcs,
        go_path = name + ".go_path",
        **kwargs
    )
