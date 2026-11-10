# Pkl Rules

[Pkl] is an embeddable configuration language with rich support for data templating and
validation. It can be used from the command line, integrated in a build pipeline, or embedded in a
program. Pkl scales from small to large, simple to complex, ad-hoc to repetitive configuration
tasks.

For further information about Pkl, check out the [official Pkl documentation].

[official Pkl documentation]: https://pkl-lang.org/main/current/index.html
[pkl]: https://pkl-lang.org

## Quick Start

### Setup

To use `rules_pkl`, enable `bzlmod` within your project, and then add the following to your `MODULE.bazel`:

```starlark
# Please check the releases page on GitHub for the latest released version
bazel_dep(name = "rules_pkl", version = "0.18.0")
```

### Toolchains

Toolchains are registered for the platforms that the selected Pkl version publishes binaries for.
Other platforms fail with `No matching toolchains found`.

Pkl `0.33.0` dropped macOS/amd64. On Intel Macs, select an older version, then run `bazel mod tidy`:

```starlark
pkl = use_extension("@rules_pkl//pkl/extensions:pkl.bzl", "pkl")
pkl.install(version = "0.32.2")
```

#### Upgrading from `rules_pkl` 0.18.0 or earlier

From `0.19.0` onwards, toolchains are generated for the selected Pkl version and registered by `rules_pkl`, instead of being defined in `@rules_pkl//pkl`:

- Remove any `register_toolchains` of `@rules_pkl//pkl:pkl_toolchain_*` or `@rules_pkl//pkl:pkl_doc_toolchain_*`; they no longer exist.
- With Pkl `0.33.0` or later, remove `pkl-cli-macos-amd64` and `pkl-doc-cli-macos-amd64` from `use_repo` (`bazel mod tidy` does this).

## Examples

See the `examples/` directory for complete examples of how to use `rules_pkl`.

## Ruleset Docs

For further information on the rules provided, check out the [`rules_pkl` documentation].

[`rules_pkl` documentation]: https://github.com/apple/rules_pkl/blob/main/docs/rules_pkl_docs.md

## Minimum required versions

### Minimum Pkl version

From `0.12.0` onwards, `rules_pkl` requires a Pkl version greater than or equal to `0.29.0`.

### Minimum JVM version

`rules_pkl` [requires at least JDK17](https://pkl-lang.org/main/current/release-notes/0.26.html#minimum-java-version-bump).
