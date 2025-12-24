ssh_port := env('DEPLOY_SSH_PORT', '22')
ssh_key := env('DEPLOY_SSH_KEY', '')
ssh_extra_opts := env('DEPLOY_SSH_OPTS', '')
ssh_control_path := "$HOME/.ssh/ctl-%r@%h:%p"
ssh_port_opt := if ssh_port == "22" { "" } else { "-p " + ssh_port }
ssh_key_opt := if ssh_key == "" { "" } else { "-i " + ssh_key }
ssh_base_opts := "-o ControlPersist=10m -o ControlPath=" + ssh_control_path + " " + ssh_port_opt + " " + ssh_key_opt + " " + ssh_extra_opts
ssh_run_opts := "-o ControlMaster=auto " + ssh_base_opts
ssh_user_host := "$DEPLOY_USER@$DEPLOY_HOST"

ssh-run := "ssh " + ssh_run_opts + " -C " + ssh_user_host + " --"
rsync := "rsync -avz --inplace --progress -e \"ssh " + ssh_run_opts + "\""
systemctl := ssh-run + " sudo systemctl"

# Deploy paths
deploy_bin := env('DEPLOY_BIN_PATH', '/usr/local/bin')
deploy_etc := env('DEPLOY_ETC_PATH', '/etc')
deploy_www := env('DEPLOY_WWW_PATH', '/var/www')
deploy_lib := env('DEPLOY_LIB_PATH', '/var/lib')
deploy_cache := env('DEPLOY_CACHE_PATH', '/var/cache')

_ssh-open:
  #!/usr/bin/env bash

  set -euo pipefail

  if ssh -o ControlPath={{ssh_control_path}} -O check {{ssh_user_host}} 2>/dev/null; then
    exit 0
  fi

  ssh -N -f -o ControlMaster=yes {{ssh_base_opts}} {{ssh_user_host}}
