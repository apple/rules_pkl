"""Tests for public interfaces of //pkl:repositories.bzl"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//pkl:repositories.bzl", "project_cache_path_and_dependencies")

# buildifier: disable=bzl-visibility
load("//pkl/private:providers.bzl", "PklCacheInfo", "PklFileInfo")

def _no_pkl_file_infos_test(ctx):
    env = unittest.begin(ctx)

    result = project_cache_path_and_dependencies(deps = [])
    expected = (None, [], [])
    asserts.equals(env, expected, result)

    return unittest.end(env)

no_pkl_file_info_test = unittest.make(_no_pkl_file_infos_test)

def _no_caches_test(ctx):
    env = unittest.begin(ctx)

    deps = [
        {
            PklFileInfo: PklFileInfo(
                dep_files = depset([]),
                caches = depset([]),
            ),
        },
    ]
    result = project_cache_path_and_dependencies(deps = deps)
    expected = (None, [], [])
    asserts.equals(env, expected, result)

    return unittest.end(env)

no_caches_test = unittest.make(_no_caches_test)

def _pkl_project_multiple_caches_test(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(
        env,
        """Only one cache item is allowed. The following labels of caches were seen:  ["cache1", "cache2"]""",
    )
    return analysistest.end(env)

def _pkl_project_cache_fake_rule(_ctx):
    """This is a rule() implementation that returns the result of project_cache_path_and_dependencies"""
    deps = [
        {
            PklFileInfo: PklFileInfo(
                dep_files = depset([]),
                caches = depset([
                    PklCacheInfo(label = "cache1", root = ("root1",), pkl_project = "project1", pkl_project_deps = ("dep1",)),
                ]),
            ),
        },
        {
            PklFileInfo: PklFileInfo(
                dep_files = depset([]),
                caches = depset([
                    PklCacheInfo(label = "cache2", root = ("root2",), pkl_project = "project2", pkl_project_deps = ("dep2",)),
                ]),
            ),
        },
    ]
    return project_cache_path_and_dependencies(deps)

pkl_project_cache_fake_rule = rule(
    implementation = _pkl_project_cache_fake_rule,
)

pkl_project_multiple_caches_test = analysistest.make(
    _pkl_project_multiple_caches_test,
    expect_failure = True,
)

_FAKE_DEPSET = depset(["dep1", "dep2"])

FakeSingleCacheTestInfo = provider(
    doc = "Provider specific to pkl_project_single_cache_fake_rule",
    fields = ["root_path", "caches", "cache_inputs"],
)

def _pkl_project_single_caches_test(ctx):
    env = analysistest.begin(ctx)
    fake_test_provider = analysistest.target_under_test(env)[FakeSingleCacheTestInfo]
    actual = (fake_test_provider.root_path, fake_test_provider.caches[0].label, fake_test_provider.cache_inputs)
    expected = ("/root/path", "cache1", [struct(path = "/root/path"), "project1", _FAKE_DEPSET])
    asserts.equals(env, expected, actual)
    return analysistest.end(env)

def _pkl_project_single_cache_fake_rule(_ctx):
    """This is a rule() implementation that returns the result of project_cache_path_and_dependencies"""
    deps = [
        {
            PklFileInfo: PklFileInfo(
                dep_files = depset([]),
                caches = depset([
                    PklCacheInfo(
                        label = "cache1",
                        root = struct(path = "/root/path"),
                        pkl_project = "project1",
                        pkl_project_deps = _FAKE_DEPSET,
                    ),
                ]),
            ),
        },
    ]

    root_path, caches, cache_inputs = project_cache_path_and_dependencies(deps)

    return [FakeSingleCacheTestInfo(
        root_path = root_path,
        caches = caches,
        cache_inputs = cache_inputs,
    )]

pkl_project_single_cache_fake_rule = rule(
    implementation = _pkl_project_single_cache_fake_rule,
)

pkl_project_single_caches_test = analysistest.make(
    _pkl_project_single_caches_test,
)

def project_cache_path_and_dependencies_test_suite(name):
    """Macro to provide tests within this file to run in BUILD.bazel

    Args:
      name: the name to be provided to `unittest.suite`.
    """
    unittest.suite(
        name,
        no_pkl_file_info_test,
        no_caches_test,
    )

    pkl_project_multiple_caches_test(
        name = "pkl_project_multiple_caches_fails_test",
        target_under_test = ":pkl_project_cache_fake_target",
    )
    pkl_project_cache_fake_rule(
        name = "pkl_project_cache_fake_target",
        tags = ["manual"],
    )

    pkl_project_single_caches_test(
        name = "pkl_project_single_cache_test",
        target_under_test = ":pkl_project_cache_single_cache_fake_target",
    )
    pkl_project_single_cache_fake_rule(
        name = "pkl_project_cache_single_cache_fake_target",
        tags = ["manual"],
    )
