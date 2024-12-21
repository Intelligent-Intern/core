#!/bin/bash

# we want a local venv for system tests - python scripts check if the infra runs correctly
install_python_and_venv() {
    venv_path="./venv"
    if [[ -d "$venv_path" ]]; then
        echo "Virtual environment found at $venv_path. Activating..."
        source "$venv_path/bin/activate"
        echo "Virtual environment activated."
    fi
    if [[ -f "$PYTHON_PREFS_FILE" ]]; then
        echo "Python installation preferences already set. Skipping Python setup."
        return
    fi
    if ! command -v python3 &> /dev/null; then
        if ask_user "Python is not installed. Do you want to install Python 3.12 and required tools?"; then
            echo "Installing Python 3.12..."
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt-get update
            sudo apt-get install -y python3.12 python3.12-venv python3.12-distutils python3-pip
            sudo ln -sf /usr/bin/python3.12 /usr/bin/python
            sudo ln -sf /usr/bin/pip3 /usr/bin/pip
        else
            echo "Skipping Python installation."
            return
        fi
    else
        echo "Python is already installed."
    fi
    if [[ ! -d "$venv_path" ]]; then
        if ask_user "Do you want to create and use a virtual environment for this process?"; then
            echo "Creating virtual environment at $venv_path..."
            sudo -u "$LOCAL_USER" python3 -m venv "$venv_path"
            echo "Activating virtual environment..."
            source "$venv_path/bin/activate"
            echo "Virtual environment activated. Installing/updating pip..."
            pip install --upgrade pip
        else
            echo "Updating pip system-wide..."
            sudo -u "$LOCAL_USER" pip install --upgrade pip --break-system-packages
        fi
    else
        echo "Activating existing virtual environment at $venv_path..."
        source "$venv_path/bin/activate"
    fi
    echo "# Preferences file to prevent reinstallation prompts" > "$PYTHON_PREFS_FILE"
    echo "Python setup complete. Preferences saved to $PYTHON_PREFS_FILE."
}