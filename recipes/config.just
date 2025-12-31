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

# Forgejo configuration
export FORGEJO_DOMAIN := env("FORGEJO_DOMAIN", "git." + env("DEPLOY_HOST", "localhost"))
export FORGEJO_HTTP_PORT := env("FORGEJO_HTTP_PORT", "3001")
export FORGEJO_SSH_PORT := env("FORGEJO_SSH_PORT", "22")
export FORGEJO_SECRET_KEY := env("FORGEJO_SECRET_KEY", "")
export FORGEJO_INTERNAL_TOKEN := env("FORGEJO_INTERNAL_TOKEN", "")

# Litestream configuration
export LITESTREAM_ACCESS_KEY_ID := env("LITESTREAM_ACCESS_KEY_ID", "")
export LITESTREAM_SECRET_ACCESS_KEY := env("LITESTREAM_SECRET_ACCESS_KEY", "")
export LITESTREAM_BUCKET := env("LITESTREAM_BUCKET", "")
export LITESTREAM_ENDPOINT := env("LITESTREAM_ENDPOINT", "https://s3.amazonaws.com")
export LITESTREAM_SYNC_INTERVAL := env("LITESTREAM_SYNC_INTERVAL", "1s")

# Generate a config file by interpolating environment variables
_generate-config name:
  @mkdir -p {{generated_dir}}
  @envsubst < {{configs_dir}}/{{name}} >| {{generated_dir}}/{{name}}
