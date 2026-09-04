import "./ssh.just"

deploy_target := env('DEPLOY_TARGET', 'linux-amd64')
accessory_repo_path := justfile_directory() + "/repo/" + replace(deploy_target, "-", "/")
