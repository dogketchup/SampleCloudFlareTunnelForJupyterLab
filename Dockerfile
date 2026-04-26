#FROM python:3.9-slim
#FROM nvidia/cuda:12.0-base
FROM python:3.11-slim

# Set environment variables to prevent .pyc files and enable buffering
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN mkdir -p /app/venv
RUN mkdir /app/projects

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
WORKDIR /app
#mount venv to venv in docker compose

COPY ./.venv /app/venv

RUN ls
RUN . venv/bin/activate

RUN useradd -m dockerUser
# Ensure dockerUser owns the project directory
RUN chown -R dockerUser:dockerUser /app/projects

USER dockerUser
WORKDIR /app/projects

EXPOSE 8888

ENTRYPOINT ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
