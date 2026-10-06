#FROM python:3.9-slim
#FROM nvidia/cuda:12.0-base
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04


# Set environment variables to prevent .pyc files and enable buffering
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/opt/conda/bin:${PATH}"
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN mkdir -p /app/
RUN mkdir /app/projects

RUN apt-get update && apt-get install -y ffmpeg build-essential cmake libopencv-dev pkg-config wget && rm -rf /var/lib/apt/lists/*
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
  bash miniconda.sh -b -p /opt/conda && \
  rm miniconda.sh && \
  conda clean -afy

COPY requirements.txt .
# Create a new environment from a yaml file (optional but recommended)



RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN conda create -n myenv python=3.12  && conda clean -afy
#RUN conda install --file requirements.txt -y && conda clean -afy 

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]
RUN conda run --live-stream -n myenv pip install -vvv --no-cache-dir -r requirements.txt




RUN conda install -n myenv --solver=libmamba -c conda-forge xeus-cling notebook -y && \
  conda clean -afy
RUN pip install opencv-python nvcc4jupyter
RUN pip install mujoco
RUN pip install mujoco-warp
RUN pip install --force-reinstall babel jupyterlab-server

RUN git clone --depth 1 --branch 4.x https://github.com/opencv/opencv.git /tmp/opencv && \
  git clone --depth 1 --branch 4.x https://github.com/opencv/opencv_contrib.git /tmp/opencv_contrib

# Build and install OpenCV with CUDA support
RUN mkdir -p /tmp/opencv/build && cd /tmp/opencv/build && \
  cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/opt/conda/envs/myenv \
  -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib/modules \
  -D WITH_CUDA=ON \
  -D WITH_CUDNN=ON \
  -D OPENCV_DNN_CUDA=ON \
  -D WITH_CUBLAS=ON \
  -D WITH_GSTREAMER=ON \
  -D WITH_LIBV4L=ON \
  -D BUILD_opencv_python3=ON \
  -D PYTHON3_EXECUTABLE=/opt/conda/envs/myenv/bin/python \
  -D PYTHON3_INCLUDE_DIR=/opt/conda/envs/myenv/include/python3.12 \
  -D PYTHON3_LIBRARY=/opt/conda/envs/myenv/lib/libpython3.12.so \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF .. && \
  make -j$(nproc) && \
  make install && \
  rm -rf /tmp/opencv /tmp/opencv_contrib



WORKDIR /app
#mount venv to venv in docker compose




RUN useradd -m dockerUser
# Ensure dockerUser owns the project directory
RUN chown -R dockerUser:dockerUser /app/projects

USER dockerUser
WORKDIR /app/projects


EXPOSE 8888
EXPOSE 8889

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "myenv", "jupyter", "lab", "--ip=0.0.0.0", "--port=8889", "--no-browser"]
