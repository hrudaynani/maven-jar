#!/bin/sh

export COMPOSE_FILE_PATH="${PWD}/target/classes/docker/docker-compose.yml"

if [ -z "${M2_HOME}" ]; then
  export MVN_EXEC="mvn"
else
  export MVN_EXEC="${M2_HOME}/bin/mvn"
fi

start() {
    docker volume create jar-acs-volume
    docker volume create jar-db-volume
    docker volume create jar-ass-volume
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d
}

start_share() {
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d jar-share
}

start_acs() {
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d jar-acs
}

down() {
    if [ -f "$COMPOSE_FILE_PATH" ]; then
        docker-compose -f "$COMPOSE_FILE_PATH" down
    fi
}

purge() {
    docker volume rm -f jar-acs-volume
    docker volume rm -f jar-db-volume
    docker volume rm -f jar-ass-volume
}

build() {
    $MVN_EXEC clean package
}

build_share() {
    docker-compose -f "$COMPOSE_FILE_PATH" kill jar-share
    yes | docker-compose -f "$COMPOSE_FILE_PATH" rm -f jar-share
    $MVN_EXEC clean package -pl jar-share,jar-share-docker
}

build_acs() {
    docker-compose -f "$COMPOSE_FILE_PATH" kill jar-acs
    yes | docker-compose -f "$COMPOSE_FILE_PATH" rm -f jar-acs
    $MVN_EXEC clean package -pl jar-integration-tests,jar-platform,jar-platform-docker
}

tail() {
    docker-compose -f "$COMPOSE_FILE_PATH" logs -f
}

tail_all() {
    docker-compose -f "$COMPOSE_FILE_PATH" logs --tail="all"
}

prepare_test() {
    $MVN_EXEC verify -DskipTests=true -pl jar-platform,jar-integration-tests,jar-platform-docker
}

test() {
    $MVN_EXEC verify -pl jar-platform,jar-integration-tests
}

case "$1" in
  build_start)
    down
    build
    start
    tail
    ;;
  build_start_it_supported)
    down
    build
    prepare_test
    start
    tail
    ;;
  start)
    start
    tail
    ;;
  stop)
    down
    ;;
  purge)
    down
    purge
    ;;
  tail)
    tail
    ;;
  reload_share)
    build_share
    start_share
    tail
    ;;
  reload_acs)
    build_acs
    start_acs
    tail
    ;;
  build_test)
    down
    build
    prepare_test
    start
    test
    tail_all
    down
    ;;
  test)
    test
    ;;
  *)
    echo "Usage: $0 {build_start|build_start_it_supported|start|stop|purge|tail|reload_share|reload_acs|build_test|test}"
esac