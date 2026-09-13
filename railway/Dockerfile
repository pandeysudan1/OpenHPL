FROM openmodelica/openmodelica:v1.27.0-minimal

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-pip python3-venv git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir \
    jupyterlab nbconvert pandas matplotlib OMPython

RUN git clone --depth 1 --branch v3.0.0 https://github.com/OpenIPSL/OpenIPSL.git /opt/OpenIPSL

WORKDIR /workspace/OpenHPL-repo
COPY . /workspace/OpenHPL-repo

RUN mkdir -p /workspace/run /workspace/results
COPY railway/start.sh /usr/local/bin/start-openhpl
RUN chmod +x /usr/local/bin/start-openhpl

ENV PORT=8888
EXPOSE 8888
CMD ["/usr/local/bin/start-openhpl"]
