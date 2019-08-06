#!/bin/bash
set -e

# determine the current directory source:
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# determine the current git hash
git_short_hash=`git rev-parse --short HEAD`
image_tag="ubuntu/adwt:$git_short_hash"

# check if the image has been build previously
if [ -z $(docker images -q $image_tag) ]; then
    # image has not been build, building it
    echo "[torcs - docker build] docker image $image_tag not found."
    docker build -t $image_tag .
fi

# start the docker container
docker run \
    --rm \
    -p 6080:80 \
    -v /dev/shm:/dev/shm \
    -v $DIR/torcs-1.3.7:/sources/torcs:ro \
    -v $DIR/torcs_ros:/opt/sources/torcs_ros:ro \
    -v $DIR/shared:/root/shared \
    -v $DIR/shared/workspace:/root/ros_workspace \
    -v $DIR/shared/vscode:/root/.vscode \
    -v $DIR/shared/vscode-cpptools:/root/.vscode-cpptools \
    -v $DIR/shared/.bash_history:/root/.bash_history \
    $image_tag