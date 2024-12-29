#!/bin/bash

handle_error() {
    echo "Error occurred: $1\n. Exiting."
    exit 1
}

install_gcc14() {
    echo "Installing GCC-14 and G++-14..."
    sudo apt install -y gcc-14 g++-14 gdb cmake valgrind|| handle_error "install_gcc14"
}

set_default_gcc14() {
    echo "Setting GCC-14 as the default GCC version..."
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 || handle_error "set_gcc_alternative"
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 || handle_error "set_g++_alternative"
    sudo update-alternatives --set gcc /usr/bin/gcc-14 || handle_error "set_gcc_as_default"
    sudo update-alternatives --set g++ /usr/bin/g++-14 || handle_error "set_g++_as_default"
}

main() {
    install_gcc14
    set_default_gcc14

    echo "GCC-14 and development tools installation complete! GCC-14 is now the default compiler."
}

main