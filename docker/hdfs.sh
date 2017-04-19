#!/bin/bash

source ../conf/hadoop.sh
set -e

# defaults
net=${NET:-"hasz"}
nodes=${NODES:-2}
volume=${VOLUME:-"/tmp/data"}

CONF_FILES="${HADOOP_CONF_FILES[@]}"
CONF_VARS="${HADOOP_CONF_VARS[@]}"

# check network existence and create it if necessary
# we need this network for the automatic service discovery in docker engine
docker network inspect ${net} > /dev/null 2>&1 && true

if [ $? -eq 1 ]; then
	net_id=$(docker network create ${net})
	echo "Created network ${net} with id ${net_id}"
fi

# bring up namenode and show its url
mkdir -p ${volume}/hdfs-namenode
hdfs_master_id=$(docker run --shm-size 2g  -d \
								-v ${volume}/hdfs-namenode:/data \
								-p 50070:50070 \
								--name hdfs-namenode \
								-h hdfs-namenode \
								--network=${net} \
								-e CONF_FILES="${CONF_FILES}" \
								-e CONF_VARS="${CONF_VARS}" \
								-e CORE_SITE_CONF \
								-e HDFS_SITE_CONF \
								-e HTTPFS_HTTP_PORT \
								-e HTTPFS_ADMIN_PORT \
								 hdfs namenode start hdfs-namenode)

sleep 2s

ip=$(docker inspect --format '{{ .NetworkSettings.Networks.'${net}'.IPAddress }}' ${hdfs_master_id})

echo Master started in:
echo http://$ip:50070

for n in $(seq 1 1 ${nodes}); do
	echo Starting node ${n}
	mkdir -p ${volume}/hdfs-datanode${n}
	datanode_id=$(docker run --shm-size 2g -d \
								-v ${volume}/hdfs-datanode${n}:/data \
								--name hdfs-datanode${n} \
								-h hdfs-datanode${n} \
								--network=${net} \
								-e CONF_FILES="${CONF_FILES}" \
								-e CONF_VARS="${CONF_VARS}" \
								-e CORE_SITE_CONF \
								-e HDFS_SITE_CONF \
								-e HTTPFS_HTTP_PORT \
								-e HTTPFS_ADMIN_PORT \
								hdfs datanode start hdfs-namenode)
done

# httpfs_node
	echo Starting httpfs node
	mkdir -p ${volume}/httpfs_node
	datanode_id=$(docker run -d \
								-v ${volume}/httpfs_node:/data \
								-p ${HTTPFS_HTTP_PORT}:${HTTPFS_HTTP_PORT} \
								--name hdfs-httpfsnode \
								-h hdfs-httpfsnode \
								--network=${net} \
								-e CONF_FILES="${CONF_FILES}" \
								-e CONF_VARS="${CONF_VARS}" \
								-e CORE_SITE_CONF \
								-e HDFS_SITE_CONF \
								-e HTTPFS_HTTP_PORT \
								-e HTTPFS_ADMIN_PORT \
								hdfs httpfs start hdfs-namenode)
