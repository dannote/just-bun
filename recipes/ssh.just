ssh_control_path := "$HOME/.ssh/ctl-%r@%h:%p"
ssh_base_opts := "-o ControlPersist=10m -o ControlPath=" + ssh_control_path
ssh_run_opts := "-o ControlMaster=auto " + ssh_base_opts
ssh_user_host := "$DEPLOY_USER@$DEPLOY_HOST"

ssh-run := "ssh " + ssh_run_opts + " -C " + ssh_user_host + " --"
rsync := "rsync -avz --progress -e \"ssh " + ssh_run_opts + "\""
systemctl := ssh-run + " sudo systemctl"

_ssh-open:
  #!/usr/bin/env bash

  set -euo pipefail

  if ssh -o ControlPath={{ssh_control_path}} -O check {{ssh_user_host}} 2>/dev/null; then
    exit 0
  fi

  ssh -N -f -o ControlMaster=yes {{ssh_base_opts}} {{ssh_user_host}}

_ssh-make-deploy-dir deploy-dir: _ssh-open
  {{ssh-run}} sudo mkdir -p {{deploy-dir}}
  {{ssh-run}} sudo chown -R $DEPLOY_USER:$DEPLOY_GROUP {{deploy-dir}}
  {{ssh-run}} sudo chmod g+s {{deploy-dir}}

_ssh: _ssh-open
  {{ssh-run}}
