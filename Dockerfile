FROM rocm/rocm-terminal

USER root
WORKDIR /root

# Install font for prompt matrix
COPY data/DejaVuSans.ttf /usr/share/fonts/truetype/

RUN apt update && apt install -y python3.8-venv wget

RUN python3.8 -m pip install -U pip

ENV VIRTUAL_ENV=/root/venv
RUN python3.8 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install -U pip ruamel.yaml

RUN pip install \
    --extra-index-url https://download.pytorch.org/whl/rocm5.1.1 \
    torch torchvision torchaudio

COPY requirements.txt /root/requirements.txt

RUN pip install -r requirements.txt

ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
EXPOSE 7860

ENV PYTHONPATH=/usr/lib/python3.8/site-packages

# For some reason taming-transformers doesn't play nicely without an editable install done manually
RUN git clone https://github.com/CompVis/taming-transformers.git && \
    cd taming-transformers && \
    pip install -e .

# Install and check stable-diffusion is installed
COPY . /root/stable-diffusion
WORKDIR /root/stable-diffusion
RUN pip install -e .

WORKDIR /root

RUN python -c "from ldm.util import instantiate_from_config"

RUN \
    rm -rf /root/stable-diffusion/models/ldm/stable-diffusion-v1 \
 && ln -sf /data/models/ldm/stable-diffusion-v1 /root/stable-diffusion/models/ldm/stable-diffusion-v1
 
 RUN \
    mkdir /root/stable-diffusion/src \
 && ln -sf /data/src/ldsr /root/stable-diffusion/src/latent-diffusion \
 && ln -sf /data/src/gfpgan /root/stable-diffusion/src/gfpgan \
 && ln -sf /data/src/realesrgan /root/stable-diffusion/src/realesrgan
 
RUN \
    mkdir -p /output /root/stable-diffusion/outputs \
 && rm -rf /root/stable-diffusion/outputs \
 && ln -sf /output/stable-diffusion/outputs /root/stable-diffusion/outputs

# Options for gfx1010 (Navi 10) cards
ENV HSA_OVERRIDE_GFX_VERSION=10.3.0

RUN pip install jupyterlab ipywidgets traceback-with-variables taichi xeus-python
RUN jupyter nbextension enable --py widgetsnbextension

RUN apt install -y libsm6 libxext6 libxrender-dev

ENTRYPOINT [ "/root/stable-diffusion/entrypoint.sh" ]
