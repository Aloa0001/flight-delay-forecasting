FROM python:3.10-bookworm

# Install Java (required for Spark) and other basics
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Spark (version 3.5.0, compatible with MLlib/Streaming)
ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt/ \
    && mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYSPARK_PYTHON=python3

# Workspace
WORKDIR /workspace
COPY . /workspace