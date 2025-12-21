# Shared systemd service commands
# Requires: service_name to be defined before importing

import "../ssh.just"
import "../colors.just"

start: _ssh-open
  {{systemctl}} start {{service_name}}

stop: _ssh-open
  {{systemctl}} stop {{service_name}}

restart: _ssh-open
  {{systemctl}} restart {{service_name}}

status: _ssh-open
  {{systemctl}} status {{service_name}}

logs *args: _ssh-open
  {{ssh-run}} journalctl -u {{service_name}} {{args}}
