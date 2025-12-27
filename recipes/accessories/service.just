# Shared systemd service commands
# Requires: service_name to be defined before importing

import "../ssh.just"
import "../colors.just"

# Start the service
start: _ssh-open
  {{systemctl}} start {{service_name}}

# Stop the service
stop: _ssh-open
  {{systemctl}} stop {{service_name}}

# Restart the service
restart: _ssh-open
  {{systemctl}} restart {{service_name}}

# Show service status
status: _ssh-open
  {{systemctl}} status {{service_name}}

# Show service logs
logs *args: _ssh-open
  {{ssh-run}} journalctl -u {{service_name}} {{args}}
