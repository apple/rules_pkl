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
bazel_dep(name = "rules_pkl", version = "0.8.0")
```

## Examples

See the `examples/` directory for complete examples of how to use `rules_pkl`.

## Ruleset Docs
For further information on the rules provided, check out the [`rules_pkl` documentation].

[`rules_pkl` documentation]: https://github.com/apple/rules_pkl/blob/main/docs/rules_pkl_docs.md

## Minimum required JVM version

From `0.26.0` onwards, Pkl [requires at least JDK17](https://pkl-lang.org/main/current/release-notes/0.26.html#minimum-java-version-bump).

This has been reflected in the `.bazelrc`.
