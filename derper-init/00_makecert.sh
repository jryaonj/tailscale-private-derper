#!/bin/bash
set -e

# configure parameters
# see https://tailscale.com/kb/1101/derp/
DERP_HOST="priv-derp"
DERP_PORT=8888
STUN_PORT=8889

# create self-signed certificate
mkdir ~/certdir && cd ~/certdir
openssl genpkey -algorithm RSA -out ${DERP_HOST}.key   
openssl req -new -key ${DERP_HOST}.key -out ${DERP_HOST}.csr
openssl x509 -req \
		-days 36500 \
		-in ${DERP_HOST}.csr \
		-signkey ${DERP_HOST}.key \
		-out ${DERP_HOST}.crt \
		-extfile <(printf "subjectAltName=DNS:${DERP_HOST}")

