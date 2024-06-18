"""Repository helper functions"""

load("//pkl/private:providers.bzl", "PklFileInfo")

def root_caches_and_dependencies(deps):
    """Given a list of Pkl dependencies, which contains a pkl_project, return the root path and the set of dependencies.

    Args:
        deps: the dependencies you wish to find the Pkl cache co-ordinates for.
    Returns:
        cache_root_path: the root path (as a string)
        caches: a depset of transitive caches
        cache_dependencies: a list of the underlying inputs that together expose `cache_root`
    """
    pkl_file_infos = [dep[PklFileInfo] for dep in deps if PklFileInfo in dep]
    if len(pkl_file_infos) == 0:
        return None, [], []

    caches = depset(transitive = [info.caches for info in pkl_file_infos]).to_list()
    if len(caches) == 0:
        return None, [], []

    if len(caches) > 1:
        cache_labels = [c.label for c in caches]
        fail("Only one cache item is allowed. The following labels of caches were seen: ", cache_labels)

    cache_root_path = caches[0].root.path
    cache_dependencies = [caches[0].root, caches[0].pkl_project, caches[0].pkl_project_deps]

    return cache_root_path, caches, cache_dependencies
