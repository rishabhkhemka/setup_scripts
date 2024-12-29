#!/bin/bash

handle_error() {
    echo "Error occurred: $1.\nExiting."
    exit 1
}

install_zsh() {
    echo "Installing Zsh and Powerline fonts..."
    sudo apt install -y zsh fonts-powerline || handle_error "install_zsh_dependencies"
    touch ~/.zshrc 
    sudo chsh -s $(which zsh) $USER || handle_error "set_zsh_as_default"
}

install_theme() {
    echo "Installing Oh My Zsh and Powerlevel10k..."
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
        || handle_error "install_oh_my_zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k \
        || handle_error "install_powerlevel10k"
}

configure_powerlevel10k() {
    echo "Configuring Powerlevel10k..."
    if [ -f ~/setup_scripts/.p10k.zsh ]; then
        cp ~/setup_scripts/.p10k.zsh ~/ || handle_error "copy_p10k_zsh"
        echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc \
            || handle_error "configure_powerlevel10k_append"
    else
        echo "~/setup_scripts/.p10k.zsh file not found. Skipping Powerlevel10k configuration."
    fi

    # Set the theme in .zshrc
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc \
        || handle_error "configure_powerlevel10k_theme"
}

install_plugins() {
    echo "Installing Zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
        || handle_error "install_autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
        || handle_error "install_syntax_highlighting"
    ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install \
        || handle_error "install gitstatusd"
    sed -i '/^plugins=(/ s/plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc \
        || handle_error "update_zshrc_plugins"
}

main() {
    install_zsh
    install_theme
    configure_powerlevel10k
    install_plugins
    echo "Zsh, Oh My Zsh, Powerlevel10k, and plugins have been installed and configured!"
}

# Run the main function
main
