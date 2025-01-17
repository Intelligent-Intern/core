#!/bin/bash

########################################################################################################################
# * # * # * # * # * # * # * # * # * # * # * #  Private PyPi Repository # * # * # * # * # * # * # * # * # * # * # * # * #
########################################################################################################################

ensure_pypi_private_repo_login() {
  chown -R "$LOCAL_USER":"$LOCAL_GROUP" "$(getent passwd "$LOCAL_USER" | cut -d: -f6)/.config/pip"
  ENCODED_USERNAME=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PYPI_REPOSITORY_USERNAME}'))")
  ENCODED_PASSWORD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PYPI_REPOSITORY_PASSWORD}'))")

# shellcheck disable=SC2024
sudo -u"$LOCAL_USER" cat > ../pip.conf <<EOL
[global]
extra-index-url = https://${ENCODED_USERNAME}:${ENCODED_PASSWORD}@${PYPI_REPOSITORY_URL}/repository/pip/simple
EOL

user_home=$(getent passwd "$LOCAL_USER" | cut -d: -f6)
pip_dir="${user_home}/.config/pip"
pip_conf="${pip_dir}/pip.conf"

if [ -f "$pip_conf" ]; then
  sudo -u"$LOCAL_USER" mkdir -p "${pip_dir}"
  sudo -u"$LOCAL_USER" mv ../pip.conf "${pip_conf}"
  chown -R "$LOCAL_USER":"$LOCAL_GROUP" "${pip_dir}"
else
  echo "${pip_conf} found"
  # shellcheck disable=SC2046
  if grep -q "pypi.kreuzung1.de" "${pip_conf}"; then
      echo "pypi already configured"
  else
      echo "Please add the following lines to your pip.conf file:"
      echo ""
      echo "[global]"
      echo "extra-index-url = https://${ENCODED_USERNAME}:${ENCODED_PASSWORD}@${PYPI_REPOSITORY_URL}/repository/pip/simple"
      echo ""
      echo "Please add the lines manually. Press any key to continue."
      # shellcheck disable=SC2162
      read -n 1 -s
  fi
fi
}

create_pypi_env() {
  if [ -z "$PYPI_REPOSITORY_URL" ]; then
    echo "PYPI_REPOSITORY_URL is not set in ./config/.env. Please check .env configuration."
    exit 1
  fi
  ENCODED_USERNAME=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${DOCKER_USERNAME}'))")
  ENCODED_PASSWORD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${DOCKER_PASSWORD}'))")
  sudo -u"$LOCAL_USER" rm -f ./config/.env.pypi
  sudo -u"$LOCAL_USER" touch ./config/.env.pypi
  # shellcheck disable=SC2024
  sudo -u"$LOCAL_USER" cat > ./config/.env.pypi <<EOL
# this file holds your credentials for the pypi repository - it is auto generated by the build.sh script - do not edit manually
PYPI_REPOSITORY_USERNAME=$ENCODED_USERNAME
PYPI_REPOSITORY_PASSWORD=$ENCODED_PASSWORD
PYPI_REPOSITORY_URL=$PYPI_REPOSITORY_URL
PIP_EXTRA_INDEX_URL=https://$ENCODED_USERNAME:$ENCODED_PASSWORD@$PYPI_REPOSITORY_URL/repository/pip/simple
PIP_INDEX_URL=https://pypi.org/simple/
PIP_TRUSTED_HOST=$PYPI_REPOSITORY_URL
EOL
  ensure_pypi_private_repo_login
}