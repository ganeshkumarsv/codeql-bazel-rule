load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":toolchain.bzl", "codeql_toolchain")

configuration = provider(
    fields = ["os", "custom_os_name", "arch", "version", "sha256"],
)

configs = [
    configuration(os = "linux", custom_os_name = "linux64", arch = "amd64", version = "v2.18.2", sha256 = "cca47f779cdea4bac726e4f23493fa23a4e79c790c05f7cdb3f60c0e1e2c8bf7"),
    configuration(os = "darwin", custom_os_name = "osx64", arch = "arm64", version = "v2.18.2", sha256 = "9e89d5b42a0debd4342be63c03606b36a61890d3691599abb70a5ee336eb6870"),
]

def repositories():
    for config in configs:
        http_archive(
            name = "codeql-bundle-{VERSION}-{OS}".format(
                VERSION = config.version,
                OS = config.os,
            ),
            build_file_content = """
exports_files(["codeql"])
filegroup(name = "go_exporter_bundle", srcs = glob(["**",]), visibility = ["//visibility:public"])
            """,
            patch_cmds = ["chmod +x codeql"],
            sha256 = config.sha256,
            strip_prefix = "codeql",
            type = "tar.gz",
            urls = [
                "https://github.com/github/codeql-action/releases/download/codeql-bundle-{VERSION}/codeql-bundle-{OS}.tar.gz".format(
                    VERSION = config.version,
                    OS = config.custom_os_name,
                ),
            ],
        )

def toolchains():
    native.toolchain_type(name = "toolchain_type")

    for config in configs:
        toolchain_name = "codeql-{OS}".format(
            OS = config.os,
        )
        exec_compatible_with = []

        if config.arch == "amd64":
            exec_compatible_with.append("@platforms//cpu:x86_64")
        else:
            exec_compatible_with.append("@platforms//cpu:{ARCH}".format(ARCH = config.arch))
        if config.os == "darwin":
            exec_compatible_with.append("@platforms//os:osx")
        else:
            exec_compatible_with.append("@platforms//os:{OS}".format(OS = config.os))

        codeql_toolchain(
            name = toolchain_name,
            executable = "@codeql-bundle-{VERSION}-{OS}//:codeql".format(
                VERSION = config.version,
                OS = config.os,
            ),
            exporter_files = ["@codeql-bundle-{VERSION}-{OS}//:go_exporter_bundle".format(
                VERSION = config.version,
                OS = config.os,
            )],
        )

        native.toolchain(
            name = "codeql_{OS}_toolchain".format(
                OS = config.os,
            ),
            exec_compatible_with = exec_compatible_with,
            toolchain = toolchain_name,
            toolchain_type = ":toolchain_type",
        )

def register_toolchains():
    for config in configs:
        native.register_toolchains(
            "//bazel_rule:codeql_{OS}_toolchain".format(
                OS = config.os,
            ),
        )
