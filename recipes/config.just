# Config templating with envsubst
# Processes configs/*.* and outputs to configs/generated/*.*

import "./ssh.just"

root := justfile_directory()
configs_dir := root + "/configs"
generated_dir := configs_dir + "/generated"

export DEPLOY_PROJECT_NAME := env("DEPLOY_PROJECT_NAME", "just-bun")
export DEPLOY_DOMAIN := env("DEPLOY_DOMAIN", env("DEPLOY_HOST", "localhost"))
export DEPLOY_BIN := deploy_bin
export DEPLOY_ETC := deploy_etc
export DEPLOY_WWW := deploy_www
export DEPLOY_LIB := deploy_lib

# Generate a config file by interpolating environment variables
_generate-config name:
  @mkdir -p {{generated_dir}}
  @envsubst < {{configs_dir}}/{{name}} >| {{generated_dir}}/{{name}}
