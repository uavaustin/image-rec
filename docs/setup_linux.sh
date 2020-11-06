#!/usr/bin/env bash

if [ -z "$1" ]
  then
    echo "No python virtual environment specified."
    USE_VENV=0
else
    echo "Python virtual environment will be created."
    USE_VENV=1
    VENV_PATH="$1"
fi

sudo apt update && \
    sudo apt upgrade -y && \
    sudo apt install -y curl gzip python3-dev build-essential

pushd $(mktemp -d)
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
rm get-pip.py
popd
python3 -m pip install --upgrade pip

if [ $USE_VENV -eq 1 ]; then
    # Create a virtual environment for hawk_eye
    python3 -m venv $VENV_PATH
    source "$VENV_PATH/bin/activate"
fi

python3 -m pip install -U Cython==0.29.21 numpy==1.17.4
python3 -m pip install -U dataclasses==0.6
python3 -m pip install -U -r requirements.txt
pre-commit && pre-commit install

IS_MAC=$(uname -a)

if [[ $IS_MAC =~ "Darwin" ]]; then
    echo "No GPU found."
    python3 -m pip install -U torch torchvision
else
    if lspci -vnnn | perl -lne 'print if /^\d+\:.+(\[\S+\:\S+\])/' | grep -q NVIDIA;
    then
        echo "GPU found."
        python3 -m pip install -U -r requirements-gpu.txt
        pushd $(mktemp -d)
        rm -rf apex
        git clone --recursive https://github.com/NVIDIA/apex
        pushd apex
        export TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5"
        git checkout 1ff54b8fed441c39dac181091b44fecdca31a403
        CUDA_HOME="/usr/local/cuda-10.2" pip install -v --no-cache-dir \
            --global-option="--cpp_ext" --global-option="--cuda_ext" ./
        popd
        popd
    else
        python3 -m pip install -U -r requirements-cpu.txt
    fi
fi

# Get bazelisk
pushd $(mktemp -d)
if [[ $IS_MAC =~ "Darwin" ]]; then
    echo "Downloading Bazelisk for Darwin"
    curl -fL -o bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.7.2/bazelisk-darwin-amd64
else
    curl -fL -o bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.7.1/bazelisk-linux-amd64
fi

chmod +x bazel
sudo mv bazel /usr/local/bin
popd

if test -f "/usr/bin/python"; then
    echo "Not making python symlink"
else
    sudo ln -sf $(which python3) /usr/bin/python
fi