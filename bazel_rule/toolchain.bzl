CodeQLInfo = provider()

def _codeql_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        codeql_info = CodeQLInfo(
            executable = ctx.attr.executable,
            exporter = ctx.files.exporter_files,
        ),
    )

codeql_toolchain = rule(
    implementation = _codeql_toolchain_impl,
    attrs = {
        "executable": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "exporter_files": attr.label_list(
        ),
    },
)
