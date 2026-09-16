FROM openmodelica/openmodelica:v1.27.0-minimal
USER root
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git ca-certificates python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
RUN printf 'loadModel(Modelica, {"4.0.0"});\ngetErrorString();\n' > /tmp/install.mos && omc /tmp/install.mos
CMD ["python3", "railway/run_simple_turbine.py"]
