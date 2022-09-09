#!/bin/bash
#
# Starts the gui inside the docker container using the conda env
#

# Array of model files to pre-download
# local filename
# local path in container (no trailing slash)
# download URL
# sha256sum
MODEL_FILES=(
    'model.ckpt /data/models/ldm/stable-diffusion-v1 https://www.googleapis.com/storage/v1/b/aai-blog-files/o/sd-v1-4.ckpt?alt=media fe4efff1e174c627256e44ec2991ba279b3816e364b49f9be2abc0b3ff3f8556'
    'GFPGANv1.3.pth /data/src/gfpgan/experiments/pretrained_models https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth c953a88f2727c85c3d9ae72e2bd4846bbaf59fe6972ad94130e23e7017524a70'
    'RealESRGAN_x4plus.pth /data/src/realesrgan/experiments/pretrained_models https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth 4fa0d38905f75ac06eb49a7951b426670021be3018265fd191d2125df9d682f1'
    'RealESRGAN_x4plus_anime_6B.pth /data/src/realesrgan/experiments/pretrained_models https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth f872d837d3c90ed2e05227bed711af5671a6fd1c9f7d7e91c911a61f155e99da'
    'project.yaml /data/src/ldsr/experiments/pretrained_models https://heibox.uni-heidelberg.de/f/31a76b13ea27482981b4/?dl=1 9d6ad53c5dafeb07200fb712db14b813b527edd262bc80ea136777bdb41be2ba'
    'model.ckpt /data/src/ldsr/experiments/pretrained_models https://heibox.uni-heidelberg.de/f/578df07c8fc04ffbadf3/?dl=1 c209caecac2f97b4bb8f4d726b70ac2ac9b35904b7fc99801e1f5e61f9210c13'
)

# Function to checks for valid hash for model files and download/replaces if invalid or does not exist
validateDownloadModel() {
    local file=$1
    local path=$2
    local url=$3
    local hash=$4

    echo "checking ${file}..."
    sha256sum --check --status <<< "${hash} ${path}/${file}"
    if [[ $? == "1" ]]; then
        echo "Downloading: ${url} please wait..."
        mkdir -p ${path}
        wget --output-document=${path}/${file} --no-verbose --show-progress --progress=dot:giga ${url}
        echo "saved ${file}"
    else
        echo -e "${file} is valid!\n"
    fi
}

# Validate model files
if [ -n "$VALIDATE_MODELS" ] || [ "$VALIDATE_MODELS" = "true" ]; then
    echo "Validating model files..."
    for models in "${MODEL_FILES[@]}"; do
        read -r -a model < <(echo "$models")
        validateDownloadModel "${model[0]}" "${model[1]}" "${model[2]}" "${model[3]}"
    done
fi

# Launch web gui
cd /root/stable-diffusion || exit 1

if [ -n "$DEBUG_LAUNCH_BASH" ]; then
    echo "Lanching bash for debugging"
    exec bash
fi

if [ -z "$*" ]; then
    launch_message="entrypoint.sh: Launching..."
else
    launch_message="entrypoint.sh: Launching with arguments $*"
fi

if [ -n "$WEBUI_RELAUNCH" ] || [ "$WEBUI_RELAUNCH" = "true" ]; then
    n=0
    while true; do

        echo "$launch_message"
        if (( n > 0 )); then
            echo "Relaunch count: ${n}"
        fi
        python -u scripts/webui.py "$@"
        echo "entrypoint.sh: Process is ending. Relaunching in 0.5s..."
        ((n++))
        sleep 0.5
    done
else
    echo "$launch_message"
    exec python -u scripts/webui.py "$@"
fi
