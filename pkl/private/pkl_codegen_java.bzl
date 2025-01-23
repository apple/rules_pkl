"""
Implementation for 'pkl_java_library' macro.
"""

load("@rules_jvm_external//:defs.bzl", "artifact")
load("@rules_pkl//pkl/private:providers.bzl", "PklCacheInfo", "PklFileInfo")

def _to_short_path(f, _expander):
    return f.tree_relative_path + "=" + f.path

# TODO: Investigate if this can be replaced with `pkg_zip` from `rules_pkg`.
def _zipit(ctx, outfile, srcs):
    zip_args = ctx.actions.args()
    zip_args.add_all("cC", [outfile.path])
    zip_args.add_all(srcs, map_each = _to_short_path)
    ctx.actions.run(
        inputs = srcs,
        outputs = [outfile],
        executable = ctx.executable._zip,
        arguments = [zip_args],
        progress_message = "Writing via zip: %s" % outfile.basename,
    )

def _pkl_java_src_jar_impl(ctx):
    modules = depset(transitive = [depset(dep[JavaInfo].runtime_output_jars) for dep in ctx.attr.module_path]).to_list()
    java_codegen_toolchain = ctx.toolchains["//pkl:codegen_toolchain_type"]

    # Generate Java from Pkl
    outdir = ctx.actions.declare_directory(ctx.attr.name, sibling = None)
    gen_args = ctx.actions.args()

    gen_args.add("--no-cache")
    if len(modules):
        gen_args.add_all(["--module-path", ctx.configuration.host_path_separator.join([module.path for module in modules])])
    if ctx.attr.generate_getters:
        gen_args.add_all(["--generate-getters"])
    gen_args.add_all("-o", [outdir.path])
    gen_args.add_all(ctx.files.srcs)

    ctx.actions.run(
        inputs = ctx.files.srcs + modules,
        outputs = [outdir],
        executable = java_codegen_toolchain.codegen_cli,
        arguments = [gen_args],
        tools = [
            java_codegen_toolchain.cli_files_to_run,
        ],
        progress_message = "Generating Java sources from Pkl %s" % (ctx.label),
    )

    # Create JAR
    outjar = ctx.outputs.out
    _zipit(
        ctx = ctx,
        outfile = ctx.outputs.out,
        srcs = [outdir],
    )

    # Return JAR
    return OutputGroupInfo(out = [outjar])

_pkl_java_src_jar = rule(
    _pkl_java_src_jar_impl,
    doc = """Create a JAR containing the generated Java source files from Pkl files.

        Args:
          name: A unique name for this target.
          srcs: The Pkl source files used to generate the Java source files.
          module_path: List of Java module targets. Must export provide the JavaInfo provider.
          **kwargs: Further keyword arguments. E.g. visibility.
        """,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".pkl"],
            doc = "The Pkl source files.",
        ),
        "generate_getters": attr.bool(
            doc = "Whether to generate getters in the AppConfig. Defaults to True",
            default = True,
        ),
        "module_path": attr.label_list(
            providers = [
                [JavaInfo],
            ],
            doc = "List of Java module targets. Must export provide the JavaInfo provider.",
        ),
        "out": attr.output(
            doc = "The output JAR generated by this action.",
        ),
        "_zip": attr.label(
            allow_single_file = True,
            cfg = "exec",
            default = "@bazel_tools//tools/zip:zipper",
            executable = True,
        ),
    },
    toolchains = [
        "//pkl:codegen_toolchain_type",
    ],
)

def pkl_java_library(name, srcs, module_path = [], generate_getters = None, deps = [], tags = [], **kwargs):
    """Create a compiled JAR of Java source files generated from Pkl source files.

    Args:
        name: A unique name for this target.
        srcs: The Pkl files that are used to generate the Java source files.
        module_path: List of Java module targets. Must export provide the JavaInfo provider.
        generate_getters: Generate private final fields and public getter methods instead of public final fields. Defaults to True.
        deps: Other targets to include in the Pkl module path when building this Java library. Must be pkl_* targets.
        tags: Bazel tags to add to this target.
        **kwargs: Further keyword arguments. E.g. visibility.
    """
    depsets = [depset([dep]) for dep in deps if PklFileInfo in dep or PklCacheInfo in dep]
    if len(depsets) != len(deps):
        fail("`deps` were provided, but there were no `PklFileInfo` or `PklCacheInfo` providers present within:", deps)

    name_generated_code = name + "_pkl"

    _pkl_java_src_jar(
        name = name_generated_code,
        srcs = srcs,
        generate_getters = generate_getters,
        module_path = module_path,
        out = "{name}_codegen.srcjar".format(name = name_generated_code),
        tags = tags,
    )

    pkl_deps = [artifact("org.pkl-lang:pkl-tools", repository_name = "rules_pkl_deps")]

    # Ensure that there are no duplicate entries in the deps
    all_deps = depset(
        pkl_deps + module_path,
        transitive = depsets,
    )

    native.java_library(
        name = name,
        srcs = [name_generated_code],
        deps = all_deps.to_list(),
        resources = srcs,
        tags = tags + [] if "no-lint" in tags else ["no-lint"],
        **kwargs
    )
