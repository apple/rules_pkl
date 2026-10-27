# Copyright © 2024-2026 Apple Inc. and the Pkl project authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Implementation for 'pkl_eval' and 'pkl_test' rules.
"""

load(":providers.bzl", "PklFileInfo")
load(":repositories.bzl", "root_caches_and_dependencies")

def _eval_symlink_pair(file):
    return [file.path, file.short_path]

def _test_symlink_pair(file):
    # Files from the cache hit this code path. For them, `short_path` starts with
    # `../` and so points to nowhere when we finally merge things. Other files
    # have a `short_path` that is valid in the runfiles tree used by test targets.
    return [file.path if file.is_source else file.short_path, file.short_path]

def _outs_root(file):
    # The directory of the output package, i.e. `file.path` without the path of the file
    # relative to its package.
    package = file.owner.package
    relative = file.short_path[len(package) + 1:] if package else file.short_path
    return file.path[:-(len(relative) + 1)]

def _prepare_pkl_script(ctx, is_test_target):
    pkl_toolchain = ctx.toolchains["//pkl:toolchain_type"]
    executable = pkl_toolchain.cli[DefaultInfo].files_to_run.executable

    # Build a forest of symlinks. Why do we need to this? It's because
    # when we execute the Pkl, the cache directory cannot be below the
    # working directory of the script because when Pkl searches for
    # dependencies, it effectively does a glob of the current working
    # directory, and if the cache is there then denormalised dependency
    # URIs won't resolve properly.
    working_dir = "%s/work" % ctx.label.name

    # Every file that has to be made available under the working directory.
    file_infos = [dep[PklFileInfo] for dep in ctx.attr.srcs + ctx.attr.deps if PklFileInfo in dep]
    all_files = depset(transitive = (
        [f[DefaultInfo].files for f in ctx.attr.srcs + ctx.attr.deps + ctx.attr.data] +
        [info.dep_files for info in file_infos]
    ))

    cache_root_path, caches, cache_deps = root_caches_and_dependencies(ctx.attr.srcs + ctx.attr.deps)

    if is_test_target and len(caches):
        # For test targets the script runs against the runfiles tree, so the
        # cache directory must be addressed by its runfiles-relative path.
        cache_root_path = caches[0].root.short_path

    # The symlinks file lists pairs of lines: the path of the file to copy followed by
    # the path to copy it to, relative to the working directory (which the symlink tool
    # receives separately).
    #
    # For `pkl_eval` it is a param file of an `Args` object (see `_pkl_eval_impl`) rather
    # than a file written at analysis time, so that the paths are subject to path mapping
    # (`--experimental_output_paths=strip`).
    symlinks_args = ctx.actions.args()
    symlinks_args.set_param_file_format("multiline")
    symlinks_args.add_all(all_files, map_each = _test_symlink_pair if is_test_target else _eval_symlink_pair, expand_directories = False)

    if len(caches):
        symlinks_args.add(caches[0].pkl_project.short_path if is_test_target else caches[0].pkl_project)
        symlinks_args.add("PklProject")
        symlinks_args.add(caches[0].pkl_project_deps.short_path if is_test_target else caches[0].pkl_project_deps)
        symlinks_args.add("PklProject.deps.json")

    symlinks_file = None
    if is_test_target:
        # Test targets don't use path mapping, so the file can be written directly.
        symlinks_file = ctx.actions.declare_file(ctx.label.name + "_symlinks.txt")
        ctx.actions.write(output = symlinks_file, content = symlinks_args)
    pkl_symlink_tool = pkl_toolchain.symlink_tool[DefaultInfo].files_to_run.executable

    suite_name_parts = []
    if is_test_target:
        package_parts = [part for part in ctx.label.package.split("/") if part != ""]

        label_parts = [part for part in ctx.label.name.split("/") if part != ""]
        suite_name_parts = package_parts + label_parts

    # The 'args' lists for 'pkl_eval' and 'pkl_test' differ because for `pkl_eval`, files are passed as file targets to enable
    # path stripping on the `ctx.Args` object when using the '--experimental_output_path=strip' flag. Currently, test rules
    # don't support using the `ctx.Args` object, which will be addressed by the following upstream PR
    # (https://github.com/bazelbuild/bazel/pull/16430).
    args = [
        executable.short_path if is_test_target else executable,
        symlinks_file.short_path if is_test_target else None,  # `pkl_eval` passes `symlinks_args` instead.
        pkl_symlink_tool.short_path if is_test_target else pkl_symlink_tool,
        "--format {}".format(ctx.attr.format) if ctx.attr.format else "",
        " ".join([f.short_path for f in (ctx.files.entrypoints or ctx.files.srcs)]),
        ctx.attr.multiple_outputs,
        working_dir,
        (cache_root_path if is_test_target else caches[0].root) if len(caches) else "",
        ".".join(suite_name_parts) if is_test_target else "",
    ]

    for k, v in ctx.attr.properties.items():
        property_flag = ["--property", "{}={}".format(k, ctx.expand_location(v, ctx.attr.data))]
        args += property_flag

    if getattr(ctx.attr, "expression"):
        expression_flag = ["-x", ctx.attr.expression]
        args += expression_flag

    if ctx.attr.no_cache:
        no_cache_flag = ["--no-cache"]
        args += no_cache_flag

    script = ctx.executable._pkl_script

    dep_files = [
        pkl_toolchain.cli[DefaultInfo].files,
        pkl_toolchain.symlink_tool[DefaultInfo].files,
    ]
    for dep in ctx.attr.deps:
        dep_files += [dep.files, dep[PklFileInfo].dep_files]

    if len(ctx.files.srcs) + len(dep_files) == 0:
        fail("{}: Cannot run pkl with no srcs or deps".format(ctx.label))

    for dep in ctx.attr.data:
        dep_files.append(dep[DefaultInfo].files)

    direct_files = [script] + ([symlinks_file] if symlinks_file else [])
    if len(caches):
        direct_files += cache_deps

    runfiles = ctx.runfiles(
        files = direct_files + [
            pkl_toolchain.cli[DefaultInfo].files_to_run.executable,
            pkl_toolchain.symlink_tool[DefaultInfo].files_to_run.executable,
        ],
        transitive_files = depset(
            transitive = [pkl_toolchain.cli[DefaultInfo].files, pkl_toolchain.symlink_tool[DefaultInfo].files, all_files] + dep_files,
        ),
    ).merge(
        pkl_toolchain.symlink_tool[DefaultInfo].default_runfiles,
    ).merge(
        pkl_toolchain.cli[DefaultInfo].default_runfiles,
    )

    return script, runfiles, args, symlinks_args

_PKL_EVAL_ATTRS = {
    "srcs": attr.label_list(
        allow_files = [".pkl"],
        doc = "The Pkl source files to be evaluated.",
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "Files to make available in the filesystem when building this configuration. These can be accessed by relative path.",
    ),
    "deps": attr.label_list(
        doc = "Other targets to include in the pkl module path when building this configuration. Must be `pkl_*` targets.",
        providers = [
            [PklFileInfo],
        ],
    ),
    "entrypoints": attr.label_list(
        allow_files = [".pkl"],
        doc = "The pkl file to use as an entry point (needs to be part of the srcs). Typically a single file.",
    ),
    "expression": attr.string(
        doc = "A pkl expression to evaluate within the module. Note that the `format` attribute does not affect how this renders.",
    ),
    "format": attr.string(
        doc = "The format of the generated file to pass when calling `pkl`. See https://pkl-lang.org/main/current/pkl-cli/index.html#command-eval.",
    ),
    "multiple_outputs": attr.bool(
        doc = """Whether to expect to render multiple file outputs. If `outs` is specified then individual generated files will
        be exposed. Otherwise, a single directory, with the name of the target, containing all generated files will be exposed.
        (see https://pkl-lang.org/main/current/pkl-cli/index.html#command-eval).""",
    ),
    "no_cache": attr.bool(
        doc = """Disable caching of packages""",
        default = False,
    ),
    "outs": attr.output_list(
        doc = "Names of the output files to generate. Defaults to `<rule name>.<format>`. If the format attribute is unset, use `<rule name>.pcf`. Expects a single file if `multiple_outputs` is not set to `True`.",
    ),
    "properties": attr.string_dict(
        doc = """Dictionary of name value pairs used to pass in Pkl external properties.
            See the Pkl docs: https://pkl-lang.org/main/current/pkl-cli/index.html#command-eval""",
    ),
    "_pkl_script": attr.label(
        default = "//pkl/private:run_pkl_script",
        executable = True,
        cfg = "exec",
    ),
}

def _pkl_eval_impl(ctx):
    pkl_toolchain = ctx.toolchains["//pkl:toolchain_type"]

    script, runfiles, common_args, symlinks_args = _prepare_pkl_script(ctx, is_test_target = False)

    if not ctx.attr.multiple_outputs and len(ctx.attr.outs) > 1:
        fail("expecting single output file, however {outputs_count} outputs have been specified. Set `multiple_outputs=True` if expecting multiple outputs."
            .format(outputs_count = len(ctx.attr.outs)))

    outputs = []
    output_location = ""
    outs_root = False

    # if `multiple_outputs`== true && `outs` is specified, then individual generated files listed in `outs` are created.
    # if `multiple_outputs`== true && `outs` is NOT specified, then a single directory of generated files is created.
    # if `multiple_outputs`== false && `outs` is specified, then the single file listed in `outs` is created.
    # if `multiple_outputs`== true && `outs` is NOT specified, then a file named with the target's label is created.

    if ctx.attr.multiple_outputs:
        if len(ctx.attr.outs) > 0:
            for output in ctx.outputs.outs:
                outputs.append(output)

            # The directory the individual outputs are relative to. It is derived from an output
            # `File` (see `_outs_root`) so that it is subject to path mapping.
            output_location = ctx.outputs.outs[0]
            outs_root = True
        else:
            output_location = ctx.actions.declare_directory(ctx.label.name)
            outputs.append(output_location)
    else:
        if len(ctx.outputs.outs) > 0:
            output_location = ctx.outputs.outs[0]
        else:
            output_format = ctx.attr.format or "pcf"
            filename = "{}.{}".format(ctx.label.name, output_format)
            output_location = ctx.actions.declare_file(filename)
        outputs.append(output_location)

    pkl_command = "eval"
    args = ctx.actions.args()
    if outs_root:
        args.add_all([output_location], map_each = _outs_root)
    else:
        args.add_all([output_location], expand_directories = False)
    args.add_all(
        [
            pkl_command,
            common_args[0],
        ],
        expand_directories = False,
    )

    # The symlinks are passed as a param file (the script receives its path as a single
    # argument), which Bazel path maps along with the rest of the command line.
    symlinks_args.use_param_file("%s", use_always = True)

    tail_args = ctx.actions.args()
    tail_args.add_all(common_args[2:], expand_directories = False)

    ctx.actions.run(
        inputs = runfiles.files,
        outputs = outputs,
        executable = script,
        tools = [
            pkl_toolchain.cli[DefaultInfo].files_to_run,
            pkl_toolchain.symlink_tool[DefaultInfo].files_to_run,
        ],
        arguments = [args, symlinks_args, tail_args],
        mnemonic = "PklEval",
        execution_requirements = {
            "supports-path-mapping": "1",
        },
    )
    return [DefaultInfo(files = depset(outputs), runfiles = ctx.runfiles(outputs))]

pkl_eval = rule(
    _pkl_eval_impl,
    attrs = _PKL_EVAL_ATTRS,
    toolchains = [
        "//pkl:toolchain_type",
    ],
    doc = "Evaluate Pkl module(s).",
)

def _pkl_test_impl(ctx):
    script, runfiles, common_args, _ = _prepare_pkl_script(ctx, is_test_target = True)

    output_script = ctx.actions.declare_file(ctx.label.name + ".sh")

    pkl_command = "test"
    test_args = [
        output_script.path,
        pkl_command,
    ] + common_args
    args_str = " ".join(["'{}'".format(str(a).replace("'", "\\'")) for a in test_args])

    cmd = """#!/usr/bin/env bash
{script} {args}
""".format(
        script = script.short_path,
        args = args_str,
    )

    ctx.actions.write(
        output = output_script,
        content = cmd,
        is_executable = True,
    )

    runfiles = runfiles.merge(ctx.runfiles(files = [script]))
    output_script = ctx.actions.declare_file(ctx.label.name + ".sh")

    return [DefaultInfo(executable = output_script, runfiles = runfiles)]

pkl_test = rule(
    implementation = _pkl_test_impl,
    attrs = _PKL_EVAL_ATTRS,
    test = True,
    toolchains = [
        "//pkl:toolchain_type",
    ],
    doc = "Create a Pkl test that can be run with Bazel.",
)
