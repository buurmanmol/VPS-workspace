#!/usr/bin/env bash
# VPS Workspace installer — run as root on Ubuntu 22.04+:
#   sudo bash install.sh
#
# Safe to re-run. It never touches your websites: everything runs as a
# dedicated, unprivileged user with capped CPU/RAM.
#
# Tunables (env vars):
#   WS_USER=claude-ws       Linux user that runs Claude (must not be an existing account you use)
#   WS_MEM_HIGH=6G          soft memory cap for that user (throttles above this)
#   WS_MEM_MAX=8G           hard memory cap (OOM-kills Claude's processes, not your sites)
#   WS_CPU_WEIGHT=50        CPU priority vs. other services (100 = normal)
#   WS_TASKS_MAX=4096       max processes/threads
#   WS_NODE=lts/*           Node version installed via nvm for the user ("" to skip)
set -euo pipefail

WS_USER="${WS_USER:-claude-ws}"
WS_MEM_HIGH="${WS_MEM_HIGH:-6G}"
WS_MEM_MAX="${WS_MEM_MAX:-8G}"
WS_CPU_WEIGHT="${WS_CPU_WEIGHT:-50}"
WS_TASKS_MAX="${WS_TASKS_MAX:-4096}"
WS_NODE="${WS_NODE-lts/*}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash $0"; exit 1; }
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || warn "Tested on Ubuntu 22.04; you are on ${PRETTY_NAME:-unknown}. Continuing."

say "Installing system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git tmux jq curl ca-certificates gnupg build-essential unzip \
  ripgrep python3 python3-venv python3-pip >/dev/null

if ! command -v gh >/dev/null; then
  say "Installing GitHub CLI (gh)"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -qq && apt-get install -y -qq gh >/dev/null
fi

say "Creating unprivileged user '$WS_USER' (no sudo)"
if ! id "$WS_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "Claude workspace" "$WS_USER" >/dev/null
  touch "$(getent passwd "$WS_USER" | cut -d: -f6)/.vps-workspace-user"
fi
WS_HOME="$(getent passwd "$WS_USER" | cut -d: -f6)"
# Never take over an account this installer didn't create (e.g. an existing 'claude' user).
if [ ! -f "$WS_HOME/.vps-workspace-user" ] && [ "${WS_ALLOW_EXISTING:-0}" != "1" ]; then
  echo "User '$WS_USER' already exists and was not created by this installer."
  echo "Pick another name (e.g. sudo WS_USER=claude-dev bash $0) or, if you really want to reuse it, set WS_ALLOW_EXISTING=1."
  exit 1
fi
WS_UID="$(id -u "$WS_USER")"
chmod 750 "$WS_HOME"
if id -nG "$WS_USER" | grep -qwE 'sudo|admin|www-data|docker'; then
  warn "User $WS_USER is in a privileged group ($(id -nG "$WS_USER")). Remove it for isolation."
fi

# Optional: let you SSH straight in as the claude user with the same key(s) as the invoking user.
if [ -n "${SUDO_USER:-}" ] && [ -f "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.ssh/authorized_keys" ] \
   && [ ! -f "$WS_HOME/.ssh/authorized_keys" ]; then
  say "Copying $SUDO_USER's SSH authorized_keys to $WS_USER (so you can: ssh $WS_USER@this-host)"
  install -d -m 700 -o "$WS_USER" -g "$WS_USER" "$WS_HOME/.ssh"
  install -m 600 -o "$WS_USER" -g "$WS_USER" \
    "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.ssh/authorized_keys" "$WS_HOME/.ssh/authorized_keys"
fi

say "Capping resources for $WS_USER so your websites keep priority"
install -d "/etc/systemd/system/user-${WS_UID}.slice.d"
cat > "/etc/systemd/system/user-${WS_UID}.slice.d/50-vps-workspace.conf" <<EOF
# Managed by VPS Workspace installer
[Slice]
MemoryHigh=${WS_MEM_HIGH}
MemoryMax=${WS_MEM_MAX}
CPUWeight=${WS_CPU_WEIGHT}
IOWeight=${WS_CPU_WEIGHT}
TasksMax=${WS_TASKS_MAX}
EOF
systemctl daemon-reload

say "Enabling lingering (services for $WS_USER start at boot without a login)"
loginctl enable-linger "$WS_USER"

say "Installing workspace tooling into $WS_HOME/vps-workspace"
if [ "$SRC_DIR" != "$WS_HOME/vps-workspace" ]; then
  rm -rf "$WS_HOME/vps-workspace.new"
  if [ -d "$SRC_DIR/.git" ]; then
    git clone -q "$SRC_DIR" "$WS_HOME/vps-workspace.new"
    # keep the original remote so `ws self-update` can pull from GitHub
    origin="$(git -C "$SRC_DIR" remote get-url origin 2>/dev/null || true)"
    [ -n "$origin" ] && git -C "$WS_HOME/vps-workspace.new" remote set-url origin "$origin"
  else
    cp -a "$SRC_DIR" "$WS_HOME/vps-workspace.new"
  fi
  rm -rf "$WS_HOME/vps-workspace"
  mv "$WS_HOME/vps-workspace.new" "$WS_HOME/vps-workspace"
fi
chown -R "$WS_USER:$WS_USER" "$WS_HOME/vps-workspace"
chmod +x "$WS_HOME/vps-workspace/bin/ws"

# Run a snippet as the workspace user. Written to a temp script so that $VARS are
# expanded by the user's shell (sudo -i would mangle the quoting).
as_user() {
  local f rc=0; f="$(mktemp)"
  { echo 'export PATH="$HOME/.local/bin:$PATH"'; echo 'cd "$HOME"'; printf '%s\n' "$*"; } > "$f"
  chmod 644 "$f"
  sudo -u "$WS_USER" -H env XDG_RUNTIME_DIR="/run/user/$WS_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$WS_UID/bus" bash -l "$f" || rc=$?
  rm -f "$f"; return $rc
}

say "Installing Claude Code (native installer) for $WS_USER"
if ! as_user 'command -v claude' >/dev/null 2>&1 && [ ! -x "$WS_HOME/.local/bin/claude" ]; then
  as_user 'curl -fsSL https://claude.ai/install.sh | bash'
fi

if [ -n "$WS_NODE" ]; then
  say "Installing Node ($WS_NODE) via nvm for $WS_USER"
  as_user 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >/dev/null'
  as_user "export NVM_DIR=\"\$HOME/.nvm\"; . \"\$NVM_DIR/nvm.sh\"; nvm install '$WS_NODE' >/dev/null && nvm alias default '$WS_NODE' >/dev/null"
fi

say "Linking the ws command and PATH"
as_user 'mkdir -p ~/.local/bin && ln -sf ~/vps-workspace/bin/ws ~/.local/bin/ws'
if ! grep -q 'VPS Workspace' "$WS_HOME/.bashrc" 2>/dev/null; then
  cat >> "$WS_HOME/.bashrc" <<'EOF'

# --- VPS Workspace ---
export PATH="$HOME/.local/bin:$PATH"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
[ -t 1 ] && command -v ws >/dev/null && ws status --brief 2>/dev/null
EOF
fi
chown "$WS_USER:$WS_USER" "$WS_HOME/.bashrc"

say "Initialising the Hub and background services"
as_user 'ws init --non-interactive' || warn "ws init reported a problem; run it again after the steps below."

cat <<EOF

$(printf '\033[1;32m')Installed.$(printf '\033[0m') Three one-time steps left (all as the $WS_USER user):

  sudo -iu $WS_USER

  1) Log Claude in (subscription):     claude        then type  /login
     -> press 'c' to copy the URL, open it on your phone/PC, paste the code back. Then /exit.

  2) Log GitHub in (fine-grained token): gh auth login     (choose: GitHub.com > HTTPS > Paste a token)
     -> then:  gh auth setup-git

  3) Finish setup & start the Hub:     ws init
     -> then:  ws attach hub     answer the one-time prompts (Enable Remote Control: y), detach with Ctrl-b d

Open the Claude app -> Code: a session called "Workspace Hub" is waiting for you.
Tell it e.g.: "Add my repo github.com/you/my-app. It's a Next.js shop; tests are npm test."
EOF
