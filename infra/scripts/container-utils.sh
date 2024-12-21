#!/bin/bash

build_python_app_base_container() {
    cd ./app/python/python-base || exit 1
    message "building python app base container" 0 6
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/python-app-base:latest
    # sudo -u"$LOCAL_USER" docker build --no-cache --progress=plain -t registry.kreuzung1.de/intelligent-intern/python-app-base:latest .
    sudo -u"$LOCAL_USER" docker build -t registry.kreuzung1.de/intelligent-intern/python-app-base:latest .
    message "Pushing python app base to Nexus" 0 6
    sudo -u"$LOCAL_USER" docker push registry.kreuzung1.de/intelligent-intern/python-app-base:latest
    cd ../../../ || exit 1
}

ensure_python_app_base_container() {
    message "rebuilding and pushing python-app-base container"
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/python-app-base:latest
    if ! docker image inspect registry.kreuzung1.de/intelligent-intern/python-app-base:latest > /dev/null 2>&1; then
        echo "python-app-base container image not found. Building container..."
        build_python_app_base_container
    else
        echo "python-app-base container image exists."
    fi
}

build_python_app_container() {
    ensure_python_app_base_container
    cd ./app/python/python-demo || exit 1
    message "building python app container" 0 6
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/python-app:latest
    # sudo -u"$LOCAL_USER" docker build --no-cache --progress=plain -t registry.kreuzung1.de/intelligent-intern/python-app:latest .
    sudo -u"$LOCAL_USER" docker build -t registry.kreuzung1.de/intelligent-intern/python-app:latest .
    message "Pushing to Nexus" 0 6
    sudo -u"$LOCAL_USER" docker push registry.kreuzung1.de/intelligent-intern/python-app:latest
    cd ../../../ || exit 1
}

ensure_python_app_container() {
    message "ensuring and pushing python-app container"
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/python-app:latest
    if ! docker image inspect registry.kreuzung1.de/intelligent-intern/python-app:latest > /dev/null 2>&1; then
        echo "python-app app container image not found. Building container..."
        build_python_app_container
    else
        echo "python-app app container image exists."
    fi
}

build_nodejs_app_container() {
    cd ./app/nodejs/app || exit 1
    sudo -u"$LOCAL_USER" docker build -t registry.kreuzung1.de/intelligent-intern/nodejs-app:latest .
    sudo -u"$LOCAL_USER" docker push registry.kreuzung1.de/intelligent-intern/nodejs-app:latest
    cd ../../../ || exit 1
}

ensure_nodejs_app_container() {
    message "rebuilding and pushing nodejs-app container"
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/nodejs-app:latest
    if ! docker image inspect registry.kreuzung1.de/intelligent-intern/nodejs-app:latest > /dev/null 2>&1; then
        echo "nodejs-app container image not found. Building container..."
        build_nodejs_app_container
    else
        echo "nodejs-app container image exists."
    fi
}

build_symfony_container() {
    cd ./infra/apache || exit 1
    # sudo -u"$LOCAL_USER" docker build --no-cache --progress=plain -t registry.kreuzung1.de/intelligent-intern/symfony:latest .

    sudo -u"$LOCAL_USER" docker build -t registry.kreuzung1.de/intelligent-intern/symfony:latest .
    sudo -u"$LOCAL_USER" docker push registry.kreuzung1.de/intelligent-intern/app:latest
    cd ../../ || exit 1
}

ensure_symfony_container() {
    # delete the container always - while we are experimenting with it - this needs to be commented out later
    sudo -u"$LOCAL_USER" docker rmi -f registry.kreuzung1.de/intelligent-intern/symfony:latest
    if ! docker image inspect registry.kreuzung1.de/intelligent-intern/symfony:latest > /dev/null 2>&1; then
        echo "symfony container image not found. Building container..."
        build_symfony_container
    else
        echo "symfony container image exists."
    fi
}