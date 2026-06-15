#!/bin/sh
#
# Generate Prometheus Node Exporter Textfile Collector metrics based on
# success/failure to pull a test image from a Docker container registry.

. /etc/generate-registry-metrics.conf

# Validate parameters
if [ "$USERNAME" = "" ] || [ "$PASSWORD" = "" ] || [ "$REGISTRY_HOST" = "" ] || [ "$REGISTRY_PORT" = "" ] || [ "$CRICTL" = "" ] || [ "$IMAGE" = "" ] || [ "$TAG" = "" ] || [ "$METRICS_FILE" = "" ]; then
    echo "ERROR: missing one or more mandatory parameters!"
    exit 1
fi

# Remove dangling image, if any
$CRICTL rmi $REGISTRY_HOST:$REGISTRY_PORT/$IMAGE:$TAG > /dev/null 2>&1 || true

# Attempt to pull the image
$CRICTL pull --creds $USERNAME:$PASSWORD $REGISTRY_HOST:$REGISTRY_PORT/$IMAGE:latest > /dev/null 2>&1
PULL_EXITCODE=$?

echo "# HELP registry_pull_timestamp Timestamp for latest registry pull" > "$METRICS_FILE"
echo "# TYPE registry_pull_timestamp gauge" >> "$METRICS_FILE"
echo "registry_pull_timestamp{image=\"$IMAGE\", tag=\"$TAG\", registry_host=\"$REGISTRY_HOST\", registry_port=\"$REGISTRY_PORT\"} $(date +'%s')" >> "$METRICS_FILE"

echo "# HELP registry_pull_passed Registry pull success or failure" >> "$METRICS_FILE"
echo "# TYPE registry_pull_passed gauge" >> "$METRICS_FILE"
echo -n "registry_pull_passed{image=\"$IMAGE\", tag=\"$TAG\", registry_host=\"$REGISTRY_HOST\", registry_port=\"$REGISTRY_PORT\"} " >> "$METRICS_FILE"

if [ $PULL_EXITCODE -eq 0 ]; then
     echo 1 >> "$METRICS_FILE"

     $CRICTL rmi $REGISTRY_HOST:$REGISTRY_PORT/$IMAGE:$TAG > /dev/null 2>&1
else
     echo 0 >> "$METRICS_FILE"
fi


