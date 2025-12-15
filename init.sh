#!/bin/bash
set -e

# install GO
# choose sudo automatically when not running as root
if [ "$EUID" -ne 0 ]; then
	SUDO=sudo
else
	SUDO=
fi

# detect architecture and pick the correct Go tarball
arch=$(uname -m)
case "$arch" in
	x86_64) gosuf="linux-amd64" ;;
	aarch64|arm64) gosuf="linux-arm64" ;;
	*) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

goversion="1.21.3"
gotar="go${goversion}.${gosuf}.tar.gz"
url="https://go.dev/dl/${gotar}"

echo "Downloading ${url}..."
wget -q --show-progress "$url" -O "$gotar"
if [ ! -f "$gotar" ]; then
	echo "Failed to download $gotar" >&2
	exit 1
fi

${SUDO} rm -rf /usr/local/go
${SUDO} tar -C /usr/local -xzf "$gotar"
rm -f "$gotar"

# ensure go is available in PATH for this script run
export PATH=$PATH:/usr/local/go/bin
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOPATH/bin

# source profile only if it exists (avoid failing under set -e)
if [ -f "$HOME/.profile" ]; then
	# shellcheck disable=SC1090
	. "$HOME/.profile"
fi


# GOPROXY=https://goproxy.cn,direct go install tailscale.com/cmd/derper@latest
command -v go >/dev/null 2>&1 || { echo "go not found after install" >&2; exit 1; }
go install tailscale.com/cmd/derper@latest


# Tailscale client / tailscaled
# Hint: prefer the official installation methods from Tailscale
# Manual options (run these yourself on the target machine):
#  - Official installer script (recommended):
#      curl -fsSL https://tailscale.com/install.sh | sh
#  - Debian/Ubuntu packaged install:
#      sudo apt-get update && sudo apt-get install -y tailscale
#  - Build from source with Go (optional):
#      GOOS=linux GOARCH=arm64 go install tailscale.com/cmd/tailscaled@latest
#      GOOS=linux GOARCH=arm64 go install tailscale.com/cmd/tailscale@latest
# Note: installation is intentionally not performed automatically by this script.
