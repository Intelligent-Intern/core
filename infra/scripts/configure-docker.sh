#!/bin/bash


########################################################################################################################
# * # * # * # * # * # * # * # * # * # * # * # * # * # * install docker # * # * # * # * # * # * # * # * # * # * # * # * #
########################################################################################################################

install_docker_and_compose() {
    message "Checking for Docker installation..."
    if [[ -f "$DOCKER_PREFS_FILE" ]]; then
        echo "Docker installation preferences already set. Skipping Docker setup."
        return
    fi
    if ! command -v docker &> /dev/null; then
        if ask_user "Docker is not installed. Do you want to install Docker?"; then
            echo "Installing Docker..."
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            echo "Adding Docker GPG key..."
            sudo mkdir -m 0755 -p /etc/apt/keyrings
            # shellcheck disable=SC2046
            curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "Setting up Docker repository..."
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            echo "Installing Docker engine..."
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            echo "Docker installed successfully."
        else
            echo "Skipping Docker installation."
        fi
    else
        echo "Docker is already installed."
    fi
    echo "Checking for Docker Compose installation..."
    if ! docker compose version &> /dev/null; then
        if ask_user "Docker Compose CLI plugin is not installed. Do you want to install Docker Compose?"; then
            echo "Installing Docker Compose..."
            sudo apt-get install -y docker-compose-plugin
            echo "Docker Compose installed successfully."
        else
            echo "Skipping Docker Compose installation."
        fi
    else
        echo "Docker Compose is already installed."
    fi
    echo "# This file prevents the Docker installation from being repeated." > "$DOCKER_PREFS_FILE"
    echo "Docker setup complete. Preferences saved to $DOCKER_PREFS_FILE."
}

########################################################################################################################
# * # * # * # * # * # * # * # * # * # * # * # Private Docker Repository  * # * # * # * # * # * # * # * # * # * # * # * #
########################################################################################################################

create_docker_env() {
  local envFilePath="./config/.env"
  local envDockerFilePath="./config/.env.docker"

  if [ ! -f "$envFilePath" ]; then
    echo "The .env file is missing - fatal error!"
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$envFilePath"
  if [ -z "$DOCKER_REGISTRY_URL" ]; then
    echo "DOCKER_REGISTRY_URL is not set in ./config/.env. fatal error!"
    exit 1
  fi

  echo "Enter your Docker registry credentials."
  # shellcheck disable=SC2162
  read -p "Username: " DOCKER_USERNAME
  # shellcheck disable=SC2162
  read -sp "Password: " DOCKER_PASSWORD
  echo
  sudo -u"$LOCAL_USER" touch "$envDockerFilePath"
  # shellcheck disable=SC2024
  sudo -u"$LOCAL_USER" cat > "$envDockerFilePath" <<EOL
# this file holds your credentials for the docker registry
REGISTRY_URL='$DOCKER_REGISTRY_URL'
DOCKER_USERNAME='$DOCKER_USERNAME'
DOCKER_PASSWORD='$DOCKER_PASSWORD'
EOL
  attempt_to_login_to_docker "$DOCKER_USERNAME" "$DOCKER_PASSWORD"
}

create_docker_env_from_local_env() {
  # first we make sure we grab the Docker registry URL from the .env file
  local envFilePath="./config/.env"
  if [ ! -f "$envFilePath" ]; then
    echo "The ./config/.env file is missing - fatal error!"
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$envFilePath"
  if [ -z "$DOCKER_REGISTRY_URL" ]; then
    echo "DOCKER_REGISTRY_URL is not set in ./config/.env. fatal error!"
    exit 1
  fi

  # then we check if the .env.local file exists and if it doesn't we create the .env.docker file
  local envLocalFilePath="./config/.env.local"
  if [ -f "$envLocalFilePath" ]; then
    echo "The .env.local file exists."
    # if it exists we source it and check if the DOCKER_USERNAME and DOCKER_PASSWORD are set
    # shellcheck disable=SC1090
    source "$envLocalFilePath"
    if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
      # no credentials in the .env.local file - then the user has to enter them in create_docker_env
      create_docker_env
    else
      # credentials are set in the .env.local file - we create the .env.docker file with those credentials
      local envDockerFilePath="./config/.env.docker"
      sudo -u"$LOCAL_USER" touch "$envDockerFilePath"
      # shellcheck disable=SC2024
      sudo -u"$LOCAL_USER" cat > "$envDockerFilePath" <<EOL
# this file holds your credentials for the docker registry - it is auto generated by the create-local-env.sh script - do not edit manually
REGISTRY_URL='$DOCKER_REGISTRY_URL'
DOCKER_USERNAME='$DOCKER_USERNAME'
DOCKER_PASSWORD='$DOCKER_PASSWORD'
EOL
      # and we delete the lines that hold the credentials and the old REGISTRY_URL from the .env.local file
      sudo -u"${SUDO_USER:-$(whoami)}" sed -i '/DOCKER_USERNAME/d' "$envLocalFilePath"
      sudo -u"${SUDO_USER:-$(whoami)}" sed -i '/DOCKER_PASSWORD/d' "$envLocalFilePath"
      sudo -u"${SUDO_USER:-$(whoami)}" sed -i '/REGISTRY_URL/d' "$envLocalFilePath"
      attempt_to_login_to_docker "$DOCKER_USERNAME" "$DOCKER_PASSWORD" "$DOCKER_REGISTRY_URL"
    fi
  else
    # if the .env.local file doesn't exist we create the .env.docker file and let the user enter the credentials
    create_docker_env
  fi
}

attempt_to_login_to_docker() {
  local USERNAME=$1
  local PASSWORD=$2
  local REGISTRY_URL=$3
  if sudo -u"$LOCAL_USER" docker login --username "$USERNAME" --password "$PASSWORD" "$REGISTRY_URL" &> /dev/null; then
    echo "Logged in to Docker registry at $REGISTRY_URL successfully."
  else
    echo "Docker login failed. Would you like to try again?"
    echo "1) Yes"
    echo "2) No"
    echo -n "Selection (1/2): "
    # shellcheck disable=SC2162
    read -n1 selection
    echo
    if [[ $selection =~ ^[1yY]$ ]]; then
      create_docker_env_from_local_env
    else
      echo "Docker login failed - exiting."
      exit 0
    fi
  fi
}

ensure_docker_login() {
  echo "Checking Docker registry login..."
  local envDockerFilePath="./config/.env.docker"
  if [ ! -f "$envDockerFilePath" ]; then
    create_docker_env_from_local_env
  fi
  # shellcheck disable=SC1090
  source "$envDockerFilePath"
  message "attempt to login to docker registry"
  attempt_to_login_to_docker "$DOCKER_USERNAME" "$DOCKER_PASSWORD" "$REGISTRY_URL"
}