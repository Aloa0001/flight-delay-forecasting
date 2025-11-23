# Use the official Debian stable image to avoid package name issues
FROM python:3.10-bookworm

# --- BASE DEPENDENCY INSTALLATION (Lab 2 Cache Layer) ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    netcat-openbsd \
    curl \
    wget \
    rsync \
    procps && \
    rm -rf /var/lib/apt/lists/*
# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# --- PYTHON PROJECT DEPENDENCIES (New Cache Layer) ---
# NOTE: The build context must be the project root (../) for this to work.
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# --- SPARK CORE INSTALLATION (The slow, but now cached layer) ---
ENV SPARK_VERSION=3.5.0 \
    HADOOP_VERSION=3 \
    SPARK_HOME=/opt/spark \
    PATH="$PATH:/opt/spark/bin:/opt/spark/sbin" \
    PYTHONPATH="$PYTHONPATH:/opt/spark/python:/opt/spark/python/lib/py4j-0.10.9.7-src.zip" \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# This step reuses the cached layer from your Lab 2 work if the ENV variables haven't changed.
RUN set -eux; \
    SPARK_TGZ="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"; \
    wget -q --retry-connrefused --waitretry=3 --timeout=30 -t 5 -O "$SPARK_TGZ" \
    "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/$SPARK_TGZ" || \
    wget -q --retry-connrefused --waitretry=3 --timeout=30 -t 5 -O "$SPARK_TGZ" \
    "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/$SPARK_TGZ"; \
    tar -xzf "$SPARK_TGZ" -C /opt; \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark; \
    rm "$SPARK_TGZ"

# --- Final Setup ---
WORKDIR /workspace
# Copy the entire project context (including data/src/notebooks)
COPY . /workspace

EXPOSE 8080 7077 4040 8888 9999

CMD ["bash"]