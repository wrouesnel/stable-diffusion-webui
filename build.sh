#!/bin/bash

args=()
if [ -n "$1" ]; then
	args+=( "-t" "$1"  )
fi

if command -v proxydetect; then
	export http_proxy=$(proxydetect 2>/dev/null)
	export https_proxy=$(proxydetect 2>/dev/null)
fi

podman build \
	-v "$HOME/.cache:/root/.cache" \
	--iidfile=.dockerid \
	"${args[@]}" \
	.
