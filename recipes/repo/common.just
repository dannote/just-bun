set unstable

import "../versions.just"

root := justfile_directory()
os := env('REPO_OS', 'linux')
arch := env('REPO_ARCH', 'amd64')
repo_path := root + "/repo/" + os + "/" + arch

repo_staging_path(name) := repo_path + "/.staging/" + name
repo_binary_path(name, version) := repo_path + "/" + name + "." + version

curl := "curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL"
curl_http1 := curl + " --http1.1"
