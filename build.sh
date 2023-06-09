#!/bin/bash
#
# -- Build Apache Spark Standalone Cluster Docker Images

# ----------------------------------------------------------------------------------------------------------------------
# -- Variables ---------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

BUILD_DATE="$(date -u +'%Y-%m-%d')"
SPARK_VERSION="3.3.1"
HADOOP_VERSION="3"
DELTA_SPARK_VERSION="2.1.0"
DELTALAKE_VERSION="0.6.4"
JUPYTERLAB_VERSION="3.6.3"
PANDAS_VERSION="2.0.1"
DELTA_PACKAGE_VERSION="delta-core_2.12:2.1.0"
SPARK_VERSION_MAJOR=${SPARK_VERSION:0:1}
SPARK_XML_PACKAGE_VERSION="spark-xml_2.12:0.16.0"

# ----------------------------------------------------------------------------------------------------------------------
# -- Functions----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

function cleanContainers() {

    container="$(docker ps -a | grep 'jupyterlab' | awk '{print $1}')"
    docker stop "${container}"
    docker rm "${container}"

    container="$(docker ps -a | grep 'spark-worker' -m 1 | awk '{print $1}')"
    while [ -n "${container}" ];
    do
      docker stop "${container}"
      docker rm "${container}"
      container="$(docker ps -a | grep 'spark-worker' -m 1 | awk '{print $1}')"
    done

    container="$(docker ps -a | grep 'spark-master' | awk '{print $1}')"
    docker stop "${container}"
    docker rm "${container}"

    container="$(docker ps -a | grep 'spark-base' | awk '{print $1}')"
    docker stop "${container}"
    docker rm "${container}"

    container="$(docker ps -a | grep 'base' | awk '{print $1}')"
    docker stop "${container}"
    docker rm "${container}"

}

function cleanImages() {

      docker rmi -f "$(docker images | grep -m 1 'jupyterlab' | awk '{print $3}')"

      docker rmi -f "$(docker images | grep -m 1 'spark-worker' | awk '{print $3}')"
      docker rmi -f "$(docker images | grep -m 1 'spark-master' | awk '{print $3}')"
      docker rmi -f "$(docker images | grep -m 1 'spark-base' | awk '{print $3}')"

      docker rmi -f "$(docker images | grep -m 1 'base' | awk '{print $3}')"

}

function cleanVolume() {
  docker volume rm "distributed-file-system"
}

function buildImages() {


    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg scala_version="${SCALA_VERSION}" \
      --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
      --build-arg deltalake_version="${DELTALAKE_VERSION}" \
      --build-arg pandas_version="${PANDAS_VERSION}" \
      -f docker/base/Dockerfile \
      -t base:latest .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg scala_version="${SCALA_VERSION}" \
      --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
      --build-arg deltalake_version="${DELTALAKE_VERSION}" \
      --build-arg pandas_version="${PANDAS_VERSION}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg hadoop_version="${HADOOP_VERSION}" \
      --build-arg delta_package_version="${DELTA_PACKAGE_VERSION}" \
      --build-arg spark_xml_package_version="${SPARK_XML_PACKAGE_VERSION}" \
      -f docker/spark-base/Dockerfile \
      -t spark-base:${SPARK_VERSION} .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      -f docker/spark-master/Dockerfile \
      -t spark-master:${SPARK_VERSION} .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      -f docker/spark-worker/Dockerfile \
      -t spark-worker:${SPARK_VERSION} .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg scala_version="${SCALA_VERSION}" \
      --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
      --build-arg deltalake_version="${DELTALAKE_VERSION}" \
      --build-arg pandas_version="${PANDAS_VERSION}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg jupyterlab_version="${JUPYTERLAB_VERSION}" \
      -f docker/jupyterlab/Dockerfile \
      -t jupyterlab:${JUPYTERLAB_VERSION}-spark-${SPARK_VERSION} .

}

# ----------------------------------------------------------------------------------------------------------------------
# -- Main --------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

cleanContainers;
cleanImages;
cleanVolume;
buildImages;
