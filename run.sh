#!/bin/bash

for path in "$HOME/sd-data" "$HOME/sd-output"; do 
    if [ ! -e "$path" ]; then
        mkdir "$path"
    fi
done

exec podman run \
    -it \
    --rm \
    -v "$HOME/.cache:/root/.cache" -v "$HOME/sd-data:/data" -v "$HOME/sd-output:/output" \
	-v "$HOME/notebooks:/root/notebooks" \
    --device=/dev/kfd \
    --device=/dev/dri \
    --ipc=host \
    --group-add keep-groups \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -p 127.0.0.1:7860:7860 \
	-p 127.0.0.1:8888:8888 \
    -e DEBUG_LAUNCH_BASH=yes \
    "$(cat .dockerid)" \
    "$@"
