To release a new version of `rules_pkl`

## Make sure all dependencies are up to date

Normally, this will mean checking the versions of any deps in the
`MODULE.bazel` file. You can run `bazel run
@rules_pkl_deps//:outdated` to check the java deps, but you'll need to
manually check the other deps in the `MODULE.bazel` file, as well as
the Pkl versions in `//pkl:repositories.bzl`

Create and land a PR if necessary.

## Pick a version number

This should be in the regular `major.minor.patch` format used by
semver. For the rest of this document, we assume you've set the env
var `TAG` to that value (eg. `export TAG=1.2.3`). NB: the tag does
_not_ begin with `v`. It's just the semver number.

## Tag the build

`git tag v${TAG} && git push --tags`

## Create a draft release on GitHub

Go to the [GitHub "new release"][new-release] page and choose the tag
you just created and pushed. Name the release after the tag (so
`v$TAG`). Now copy-and-paste the following, but please edit the
release number:

````markdown
## Pkl Rules

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
bazel_dep(name = "rules_pkl", version = "X.Y.Z")
```

## Examples

See the `examples/` directory for complete examples of how to use `rules_pkl`.

## Ruleset Docs

For further information on the rules provided, check out the [`rules_pkl` documentation].

[`rules_pkl` documentation]: https://github.com/apple/rules_pkl/blob/main/docs/rules_pkl_docs.md
````

You can click the "Generate release notes" button to have some
skeleton release notes created, but go through and edit. Please make
sure that all PRs by people who are not on the team are mentioned.

## Upload a `rules_pkl` archive

Bazel uses integrity hashes to ensure that the dependency requested is
the dependency you get, but GitHub occasionally changes how
auto-generated source archives are created. To avoid this, we create
and upload our own source archive as an asset on the release.

`./scripts/push-release-artifacts ${TAG}`

You will need `gh` installed locally for this to work.

## Mark the release as the latest release

In the GitHub UI, mark the release as the latest release.

## Prepare the BCR PR

Before people can download the latest release from the BCR, we need to
create a new PR for that repo.

### Clone the BCR

`git https://github.com/bazelbuild/bazel-central-registry.git /Dev/src/bcr`

You should clone the repo to somewhere that's sensible for you, of
course :) Store the absolute path in the `BCR_REPO` env var.

### Now generate the PR

In the `rules_pkl` repo:

`./scripts/prep-bcr-pr.sh "${BCR_REPO}" "${TAG}"`

You may be asked to fill in some details, but most of the work should
be done for you.

Now, back in the `bazel-central-registry` repo:

```shell
cd "${BCR_REPO}"
git checkout -b release-rules-pkl
git add modules/rules_pkl
git commit -am "Release rules_pkl ${TAG}"
```

Push the new branch to your own fork of the BCR, and follow the
regular workflow to create a PR and have it merged.

## Announce on any channels you may wish to

Let the world know that new goodness is available!

[new-release]: https://github.com/apple/rules_pkl/releases/new