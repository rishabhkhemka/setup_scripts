#!/bin/bash

handle_error() {
    echo -e "Error occurred: $1\nExiting."
    exit 1
}

DEFAULT_SHELL="/bin/bash"
USERNAME=""
PASSWORD=""
SUDO_ACCESS=""
PASSWORDLESS_SUDO=""

usage() {
    echo "Usage: $0 --username <username> --password <password> --sudo <yes|no> --passwordless <yes|no>"
    echo "Options:"
    echo "  --username       Username for the new user (default: 'user')"
    echo "  --password       Password for the new user (default: randomly generated)"
    echo "  --sudo           Grant sudo access (yes or no, default: no)"
    echo "  --passwordless   Enable passwordless sudo (yes or no; requires --sudo yes)"
    exit 1
}

trim() {
    echo "$1" | xargs
}

validate_yes_no() {
    local value="$1"
    if [[ "$value" != "yes" && "$value" != "no" ]]; then
        handle_error "Invalid value for $2: $value. Allowed values are 'yes' or 'no'."
    fi
}

get_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --username)
                USERNAME=$(trim "$2")
                shift 2
                ;;
            --password)
                PASSWORD=$(trim "$2")
                shift 2
                ;;
            --sudo)
                SUDO_ACCESS=$(trim "$2")
                shift 2
                ;;
            --passwordless)
                PASSWORDLESS_SUDO=$(trim "$2")
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done

    [[ -z "$USERNAME" ]] && USERNAME="user"
    [[ -z "$PASSWORD" ]] && PASSWORD=$(openssl rand -base64 12 2>/dev/null || date +%s | sha256sum | base64 | head -c 12)
    [[ -z "$SUDO_ACCESS" ]] && SUDO_ACCESS="no"
    [[ -z "$PASSWORDLESS_SUDO" ]] && PASSWORDLESS_SUDO="no"

    validate_yes_no "$SUDO_ACCESS" "--sudo"
    validate_yes_no "$PASSWORDLESS_SUDO" "--passwordless"
    
    # Print parsed configuration
    echo "Configuration:"
    echo "  Username:         $USERNAME"
    echo "  Password:         $PASSWORD"
    echo "  Sudo Access:      $SUDO_ACCESS"
    echo "  Passwordless Sudo: $PASSWORDLESS_SUDO"
}

create_user() {
    sudo useradd -m -s $DEFAULT_SHELL "$USERNAME" || handle_error "create_user"
}

set_password() {
    echo "$USERNAME:$PASSWORD" | sudo chpasswd || handle_error "set_password"
}

grant_sudo_access() {
    if [[ "$SUDO_ACCESS" == "yes" ]]; then
        echo "Granting sudo access to ${USERNAME}..."
        sudo usermod -aG sudo "${USERNAME}" || handle_error "grant_sudo_access"
        
        if [[ "$PASSWORDLESS_SUDO" == "yes" ]]; then
            echo "Granting passwordless sudo access to ${USERNAME}..."
            SUDOERS_FILE="/etc/sudoers.d/${USERNAME}"
            echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null || handle_error "grant_passwordless_sudo"
            sudo chmod 0440 "$SUDOERS_FILE" || handle_error "set_sudoers_permissions"
        fi
    fi
}


copy_zsh_from_root() {
    [[ ! -f /root/.zshrc || ! -f /root/.p10k.zsh ]] && handle_error "Required Zsh configuration files not found in /root."
    sudo cp -r /root/.oh-my-zsh /home/$USERNAME/ &&
    sudo cp /root/.zshrc /home/$USERNAME/ &&
    sudo cp /root/.p10k.zsh /home/$USERNAME/ &&
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.* &&
    sudo chsh -s "$(which zsh)" "${USERNAME}" &&
    su $USERNAME -c "~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install" ||
    handle_error "copy_zsh_from_root"
}

main() {
    [[ $EUID -ne 0 ]] && handle_error "This script must be run as root."
    get_flags "$@"
    create_user
    set_password
    grant_sudo_access
    copy_zsh_from_root
    echo "User setup complete!"
}

main "$@"
