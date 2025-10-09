# How to Contribute

## Formatting

Starlark files should be formatted by buildifier.
We suggest using a pre-commit hook to automate this.
First [install pre-commit](https://pre-commit.com/#installation),
then run

```shell
pre-commit install
```

Otherwise, later tooling on CI will inform you about formatting/linting violations.

## Updating BUILD files

Some targets are generated from sources.
Currently, this is just the `bzl_library` targets.
Run `bazel run //:gazelle` to keep them up-to-date.

## Updating maven lock files

Once the `MODULE.bazel` and `//pkl:private:constants.bzl` files have been updated, you
can update the maven lock files using:

```
bazel run @unpinned_rules_pkl_deps//:pin
bazel run @unpinned_custom_pkl_java_library_maven_deps//:pin
```

## Using this as a development dependency of other rules

You'll commonly find that you develop in another WORKSPACE, such as
some other ruleset that depends on rules_pkl, or in a nested
WORKSPACE in the integration_tests folder.

To always tell Bazel to use this directory rather than some release
artifact or a version fetched from the internet, run this from this
directory:

```sh
OVERRIDE="--override_repository=rules_pkl=$(pwd)/rules_pkl"
echo "common $OVERRIDE" >> ~/.bazelrc
```

This means that any usage of `@rules_pkl` on your system will point to this folder.

## Releasing

See [the wiki](https://github.com/apple/rules_pkl/wiki/Release-Process) for the release process.
