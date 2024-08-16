#!/bin/bash

SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

COMMON_NAME=managedev
# FIXME: Adjust custom classes package path. 
# In current setup all Java classes are located under custom.* package
# therefore package path is 'custom'. Other example might be:
# com.ibm.tivoli.maximo.custom.* -> com/ibm/tivoli/maximo/custom
PACKAGE_PATH=custom
# FIXME: Adjust custom classes build locations
MAXIMO_HOST_MBO_CLASS=/opt/manage/businessobjects/classes/$PACKAGE_PATH
MAXIMO_HOST_UI_CLASS=/opt/manage/maximouiweb/classes/$PACKAGE_PATH
MAXIMO_CONT_BASE=/config/apps/maximo-all.ear
MAXIMO_CONT_MBO_CLASS=$MAXIMO_CONT_BASE/businessobjects.jar/$PACKAGE_PATH
MAXIMO_CONT_UI_CLASS=$MAXIMO_CONT_BASE/maximouiweb.war/WEB-INF/classes/$PACKAGE_PATH
TZ=$(cat /etc/timezone)

if [ "$#" -eq 0 ] || [ "$1" = "all" ] || [ "$1" = "run" ] || [ "$1" = "up" ]; then
    # Make sure local directories exist before mounting them to the container
    # This is to handle cases when containers are created before Java classes 
    # build output directory exists.
    mkdir -p $MAXIMO_HOST_MBO_CLASS $MAXIMO_HOST_UI_CLASS

    podman network rm -f $COMMON_NAME 

    echo "Building container image..."
    podman build --tag $COMMON_NAME $SCRIPT_DIR
    [ "$?" != "0" ] && echo "Podman image build failed. Fix error and re-run the script." && exit 1

    echo "Creating container..."
    podman network create $COMMON_NAME 
    podman container run -dt --network $COMMON_NAME --name manage --replace \
        -p 9080:9080 \
        -p 7777:7777 \
        -v /tmp:/tmp \
        -v $MAXIMO_HOST_MBO_CLASS:$MAXIMO_CONT_MBO_CLASS \
        -v $MAXIMO_HOST_UI_CLASS:$MAXIMO_CONT_UI_CLASS \
        -e TZ=$TZ \
        localhost/$COMMON_NAME
fi

if [ "$#" -eq 1 ] && [ "$1" = "start" ]; then
    echo "Starting container..."
    podman container start manage
fi

if [ "$#" -eq 1 ] && [ "$1" = "stop" ]; then
    echo "Stopping container..."
    podman container stop -i manage
fi

if [ "$#" -eq 1 ] && [ "$1" = "down" ]; then
    echo "Decommissioning container..."
    podman network rm -f $COMMON_NAME 
fi
