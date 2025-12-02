# Copyright © 2024-2025 Apple Inc. and the Pkl project authors. All rights reserved.
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
Implementation of 'pkl_doc' macro.
"""

def _pkl_doc_impl(ctx):
    """Generate HTML documentation from Pkl files."""
    modules = [module.path for module in ctx.files.deps]

    # Generate HTML from Pkl

    outfile = ctx.outputs.out
    if outfile == None:
        outfile = ctx.actions.declare_file(ctx.label.name + "_docs.zip")

    pkl_doc_toolchain = ctx.toolchains["//pkl:doc_toolchain_type"]
    pkl_doc_cli = pkl_doc_toolchain.pkl_doc_cli

    outdir_path = outfile.path + ".tmpdir"
    command = "{executable} -o {output}".format(
        executable = pkl_doc_cli.path,
        output = outdir_path,
    )
    if modules:
        command += " --module-path " + ctx.configuration.host_path_separator.join([module.path for module in modules])
    for file in ctx.files.srcs:
        command += " " + file.path

    # The zip binary only accepts files, not directories, so we need to do the `find` ourself.
    # Then we need to translate index.html into index.html=bazel-out/.../index.html to strip the bazel-out/... prefixes from the output zip.
    command += " && (cd {outdir} && find . -type f) | sed -e 's#^\\./\\(.*\\)$#\\1={outdir}/\\1#' | xargs {zip} cC {outfile}".format(
        zip = ctx.executable._zip.path,
        outfile = outfile.path,
        outdir = outdir_path,
    )

    ctx.actions.run_shell(
        command = command,
        inputs = ctx.files.deps + ctx.files.srcs,
        outputs = [outfile],
        tools = [
            pkl_doc_cli,
            ctx.executable._zip,
        ],
        progress_message = "Generating Pkl docs",
    )

    return OutputGroupInfo(out = [outfile])

_pkl_doc = rule(
    _pkl_doc_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".pkl"],
            doc = "The Pkl soruce files used to generate the documentation.",
        ),
        "deps": attr.label_list(
            mandatory = False,
            allow_files = [".pkl"],
            doc = "Other targets to include in the Pkl module path when generating the documentation.",
        ),
        "out": attr.output(
            doc = "The generated output zip file containing pkl documentation.",
        ),
        "_zip": attr.label(
            allow_single_file = True,
            cfg = "exec",
            default = "@bazel_tools//tools/zip:zipper",
            executable = True,
        ),
    },
    toolchains = [
        "@rules_pkl//pkl:doc_toolchain_type",
    ],
)

def pkl_doc(name, srcs, **kwargs):
    """Generate documentation website for Pkl files.

    Args:
        name: A unique name for this target.
        srcs: The Pkl source files to be documented.
        **kwargs: Further keyword arguments. E.g. visibility.
    """
    if "out" not in kwargs:
        kwargs["out"] = name + "_docs.zip"
    _pkl_doc(
        name = name,
        srcs = srcs,
        **kwargs
    )
