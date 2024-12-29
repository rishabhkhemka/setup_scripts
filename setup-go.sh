#!/bin/bash

handle_error() {
    echo -e "Error occurred: $1\nExiting."
    exit 1
}

install_go() {
    echo "Fetching the latest version of Go..."

    # Fetch the latest version from Go's download page
    LATEST_VERSION=$(curl -s https://go.dev/dl/ | grep -oP '(?<=go)[0-9]+\.[0-9]+\.[0-9]+' | head -1) || handle_error "fetch_latest_go_version"
    echo "Latest Go version is go${LATEST_VERSION}."

    # Construct the download URL
    DOWNLOAD_URL="https://go.dev/dl/go${LATEST_VERSION}.linux-amd64.tar.gz"

    # Download and install
    echo "Downloading Go from $DOWNLOAD_URL..."
    wget -q "$DOWNLOAD_URL" -O /tmp/go.tar.gz || handle_error "download_go"

    echo "Extracting Go to /usr/local..."
    sudo rm -rf /usr/local/go || handle_error "remove_existing_go"
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz || handle_error "extract_go"

    # Clean up
    rm -f /tmp/go.tar.gz
}

update_zsh_config() {
    echo "Updating zsh configuration to include Go path..."

    # Add the Go binary path to /etc/zsh/zshenv (for all users)
    if ! grep -q "/usr/local/go/bin" /etc/zsh/zshenv; then
        echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee -a /etc/zsh/zshenv > /dev/null || handle_error "add_go_to_zshenv"
        echo "Go binary path added to /etc/zsh/zshenv"
    else
        echo "Go path is already in /etc/zsh/zshenv. Skipping update."
    fi
}

update_skel_profile() {
    echo "Updating /etc/skel/.profile to include Go path for new users..."

    # Check if the Go binary path is already in the /etc/skel/.profile
    if ! grep -q "/usr/local/go/bin" /etc/skel/.profile; then
        # Add Go binary path to /etc/skel/.profile
        echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee -a /etc/skel/.profile > /dev/null || handle_error "add_go_to_skel_profile"
        echo "Go binary path added to /etc/skel/.profile"
    else
        echo "Go path is already in /etc/skel/.profile. Skipping update."
    fi
}

main() {
    install_go
    update_zsh_config
    update_skel_profile
    echo "Go installation complete for all users, including future users!"
}

main
