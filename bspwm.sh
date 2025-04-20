#!/bin/bash

# ========================================
# Script Banner and Intro
# ========================================
clear
echo "
 +-+-+-+-+-+-+-+-+-+-+-+-+-+ 
 |b|s|p|w|m| | |s|c|r|i|p|t|  
 +-+-+-+-+-+-+-+-+-+-+-+-+-+                                                                            
"

CLONED_DIR="$HOME/bspwm-setup"
CONFIG_DIR="$HOME/.config/bspwm"
INSTALL_DIR="$HOME/installation"
GTK_THEME="https://github.com/vinceliuice/Orchis-theme.git"
ICON_THEME="https://github.com/vinceliuice/Colloid-icon-theme.git"

# ========================================
# User Confirmation
# ========================================
echo "This script will install and configure bspwm on your Debian system."
read -p "Do you want to continue? (y/n) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 1
fi

sudo apt-get update 
sudo apt-get upgrade -y
sudo apt-get clean

# ========================================
# Initialization
# ========================================
mkdir -p "$INSTALL_DIR" || { echo "Failed to create installation directory."; exit 1; }

cleanup() {
    rm -rf "$INSTALL_DIR"
    echo "Installation directory removed."
}
trap cleanup EXIT

# ========================================
# Check for Existing BSPWM Configuration
# ========================================
check_bspwm() {
    if [ -d "$CONFIG_DIR" ]; then
        echo "An existing ~/.config/bspwm directory was found."
        read -p "Would you like to back it up before proceeding? (y/n) " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
            backup_dir="$HOME/.config/bspwm_backup_$timestamp"
            mv "$CONFIG_DIR" "$backup_dir"
            echo "Backup created at $backup_dir"
        else
            echo "Skipping backup. Your existing config will be overwritten."
        fi
    fi
}

# ========================================
# Copy Config Files
# ========================================
setup_bspwm_config() {
    echo "Moving configuration files..."
    mkdir -p "$CONFIG_DIR"
    cp -r "$CLONED_DIR/bspwmrc" "$CONFIG_DIR/" || echo "Warning: Failed to copy bspwmrc."
    for dir in dunst fonts picom polybar rofi scripts sxhkd wallpaper; do
        cp -r "$CLONED_DIR/$dir" "$CONFIG_DIR/" || echo "Warning: Failed to copy $dir."
    done
    echo "BSPWM configuration files copied successfully."
}

# ========================================
# Install Packages
# ========================================
install_packages() {
    echo "Installing required packages..."
    sudo apt-get install -y xorg xorg-dev xbacklight xbindkeys xvkbd xinput build-essential bspwm sxhkd polybar network-manager-gnome pamixer 
    sudo apt-get install -y nemo lxappearance dialog mtools avahi-daemon acpi acpid gvfs-backends gnome-power-manager pavucontrol pulsemixer 
    sudo apt-get install -y feh fonts-recommended fonts-font-awesome fonts-terminus exa suckless-tools viewnior rofi dunst playerctl brightnessctl wmctrl
    sudo apt-get install -y libnotify-bin xdotool unzip libnotify-dev pipewire-audio nala micro xdg-user-dirs-gtk terminator lightdm || echo "Warning: Package installation failed."
    echo "Package installation completed."
}

# ========================================
# Enable Required Services
# ========================================
enable_services() {
    echo "Enabling required services..."
    sudo systemctl enable avahi-daemon || echo "Warning: Failed to enable avahi-daemon."
    sudo systemctl enable acpid || echo "Warning: Failed to enable acpid."
    echo "Services enabled."
}

# ========================================
# Setup User Directories
# ========================================
setup_user_dirs() {
    echo "Updating user directories..."
    xdg-user-dirs-update || echo "Warning: Failed to update user directories."
    mkdir -p ~/Screenshots/ || echo "Warning: Failed to create Screenshots directory."
    echo "User directories updated."
}

# ========================================
# Command Existence Checker
# ========================================
command_exists() {
    command -v "$1" &>/dev/null
}

# ========================================
# Install Build Tools
# ========================================
install_reqs() {
    echo "Installing required dependencies..."
    sudo apt-get install -y cmake meson ninja-build curl pkg-config || { echo "Package installation failed."; exit 1; }
}

# ========================================
# Install Picom (FT Labs Fork)
# ========================================
install_ftlabs_picom() {
    if command_exists picom; then
        echo "Picom is already installed. Skipping installation."
        return
    fi
    sudo apt-get install -y libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev \
    libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-dpms0-dev libxcb-glx0-dev \
    libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev \
    libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev libxext-dev uthash-dev wget curl jq xsettingsd inxi xinit

    mkdir -p ~/.config/rofi
    rofi -dump-config > ~/.config/rofi/config.rasi
    mkdir -p ~/.config/rofi/themes ~/.config/rofi/scripts ~/.config/rofi/bin

    git clone https://github.com/FT-Labs/picom "$INSTALL_DIR/picom"
    cd "$INSTALL_DIR/picom"
    meson setup --buildtype=release build
    ninja -C build
    sudo ninja -C build install
}

# ========================================
# Install Fastfetch
# ========================================
install_fastfetch() {
    if command_exists fastfetch; then
        echo "Fastfetch is already installed. Skipping."
        return
    fi
    git clone https://github.com/fastfetch-cli/fastfetch "$INSTALL_DIR/fastfetch"
    cd "$INSTALL_DIR/fastfetch"
    cmake -S . -B build
    cmake --build build
    sudo mv build/fastfetch /usr/local/bin/
    mkdir -p "$HOME/.config"
    mv .config/fastfetch "$HOME/.config/"
}

# ========================================
# Install WezTerm
# ========================================
install_wezterm() {
    if command_exists wezterm; then
        echo "Wezterm is already installed. Skipping."
        return
    fi

    TMP_DEB="/tmp/wezterm.deb"
    wget -O "$TMP_DEB" "https://github.com/wezterm/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203-110809-5046fc22.Debian12.deb"
    sudo apt install -y "$TMP_DEB"
    rm -f "$TMP_DEB"

    mkdir -p "$HOME/.config/wezterm"
    echo "-- Add your wezterm.lua config here --" > "$HOME/.config/wezterm/wezterm.lua"
}

# ========================================
# Install Fonts
# ========================================
install_fonts() {
    mkdir -p ~/.local/share/fonts
    fonts=( "FiraCode" "Hack" "JetBrainsMono" "RobotoMono" "SourceCodePro" "UbuntuMono" )

    for font in "${fonts[@]}"; do
        if ls ~/.local/share/fonts/$font/*.ttf &>/dev/null; then
            echo "Font $font already exists."
        else
            wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$font.zip" -P /tmp
            unzip -q /tmp/$font.zip -d ~/.local/share/fonts/$font/
            rm /tmp/$font.zip
        fi
    done

    fc-cache -f
}

# ========================================
# Install GTK & Icon Themes
# ========================================
install_theming() {
    GTK_THEME_NAME="Orchis-Teal-Dark"
    ICON_THEME_NAME="Colloid-Teal-Everforest-Dark"

    if [ -d "$HOME/.themes/$GTK_THEME_NAME" ] || [ -d "$HOME/.icons/$ICON_THEME_NAME" ]; then
        echo "Themes already installed. Skipping."
        return
    fi

    git clone "$GTK_THEME" "$INSTALL_DIR/Orchis-theme"
    cd "$INSTALL_DIR/Orchis-theme"
    yes | ./install.sh -c dark -t teal orange --tweaks black

    git clone "$ICON_THEME" "$INSTALL_DIR/Colloid-icon-theme"
    cd "$INSTALL_DIR/Colloid-icon-theme"
    ./install.sh -t teal orange -s default gruvbox everforest
}

# ========================================
# GTK Theme Settings
# ========================================
change_theming() {
    mkdir -p ~/.config/gtk-3.0

    cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Orchis-Teal-Dark
gtk-icon-theme-name=Colloid-Teal-Everforest-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
EOF

    cat << EOF > ~/.gtkrc-2.0
gtk-theme-name="Orchis-Teal-Dark"
gtk-icon-theme-name="Colloid-Teal-Everforest-Dark"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Adwaita"
EOF

    echo "GTK theming applied."
}

# ========================================
# Optional: Replace .bashrc
# ========================================
replace_bashrc() {
    read -p "Would you like to replace your .bashrc with a custom one? (y/n) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp "$CLONED_DIR/.bashrc" "$HOME/.bashrc" && echo ".bashrc replaced."
    fi
}

# ========================================
# Replace default terminal in sxhkd
# ========================================
set_default_terminal() {
    sed -i 's|termite|terminator|g' "$CONFIG_DIR/sxhkd/sxhkdrc"
}

# ========================================
# Ask for LightDM Installation
# ========================================
install_lightdm() {
    read -p "Do you want to install and configure LightDM? (y/n) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        chmod +x "$CLONED_DIR/lightdm.sh"
        bash "$CLONED_DIR/lightdm.sh"
    else
        echo "Skipping LightDM installation."
    fi
}

# ========================================
# Main Execution
# ========================================
echo "Starting full bspwm environment setup..."

check_bspwm
setup_bspwm_config
install_packages
enable_services
setup_user_dirs
install_reqs
install_ftlabs_picom
install_fastfetch
install_wezterm
install_fonts
install_theming
change_theming
replace_bashrc
set_default_terminal
install_lightdm

echo "🎉 All installations completed successfully!"
