i need .config directories for bspwm sxhkd polybar
#!/bin/bash
# ========================================
# Full bspwm Setup Script for Debian
# ========================================

# ========================================
# User Confirmation
# ========================================
echo "This script will install and configure bspwm on your Debian system."
read -p "Do you want to continue? (y/n) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 1
fi

# ========================================
# Initialization
# ========================================
sudo apt-get update 
sudo apt-get upgrade -y
sudo apt-get clean

cleanup() {
    rm -rf "$INSTALL_DIR"
    echo "Installation directory removed."
}
trap cleanup EXIT

# ========================================
# Install Packages
# ========================================
install_packages() {
    echo "Installing required packages..."
    sudo apt-get install -y \
        xorg xorg-dev xbacklight xbindkeys xvkbd xinput build-essential \
        bspwm sxhkd polybar network-manager-gnome pamixer \
        nemo lxappearance dialog mtools avahi-daemon acpi acpid gvfs-backends \
        gnome-power-manager pavucontrol pulsemixer bluez blueman \
        feh fonts-recommended fonts-font-awesome fonts-terminus exa \
        suckless-tools viewnior rofi dunst playerctl brightnessctl wmctrl \
        libnotify-bin xdotool unzip libnotify-dev pipewire-audio \
        nala micro xdg-user-dirs-gtk terminator
    echo "Package installation completed."
}

# ========================================
# Enable Required Services
# ========================================
enable_services() {
    echo "Enabling required services..."
    sudo systemctl enable avahi-daemon
    sudo systemctl enable acpid
    sudo systemctl enable bluetooth
    sleep 2
    echo "Services enabled."
}

# ========================================
# Setup User Directories
# ========================================
setup_user_dirs() {
    echo "Updating user directories..."
    xdg-user-dirs-update
    xdg-user-dirs-gtk-update 
    echo "User directories updated."
}

# ========================================
# Install Build Tools
# ========================================
install_reqs() {
    echo "Installing required dependencies..."
    sudo apt-get install -y cmake meson ninja-build curl pkg-config || { echo "Package installation failed."; exit 1; }
}

    sudo apt-get install -y \
        libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev \
        libpcre2-dev libpixman-1-dev libx11-xcb-dev libxcb1-dev \
        libxcb-composite0-dev libxcb-damage0-dev libxcb-dpms0-dev \
        libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev \
        libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev \
        libxcb-util-dev libxcb-xfixes0-dev libxext-dev uthash-dev \
        wget curl jq xsettingsd inxi xinit

    mkdir -p ~/.config/rofi
    rofi -dump-config > ~/.config/rofi/config.rasi
    mkdir -p ~/.config/rofi/themes ~/.config/rofi/scripts ~/.config/rofi/bin

    git clone https://github.com/FT-Labs/picom "$INSTALL_DIR/picom"
    cd "$INSTALL_DIR/picom" || exit 1
    meson setup --buildtype=release build
    ninja -C build
    sudo ninja -C build install
}



# ========================================
# Install WezTerm
# ========================================
install_wezterm() {
    if command_exists wezterm; then
        echo "Wezterm is already installed. Skipping."
        return
    fi

    wget -O "$TMP_DEB" "https://github.com/wezterm/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203-110809-5046fc22.Debian12.deb"
    sudo apt-get install -y
    rm wezterm-20240203-110809-5046fc22.Debian12.deb

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
    GTK_THEME="https://github.com/vinceliuice/Orchis-theme"
    ICON_THEME="https://github.com/vinceliuice/Colloid-icon-theme"

    GTK_THEME_NAME="Orchis-Teal-Dark"
    ICON_THEME_NAME="Colloid-Teal-Everforest-Dark"

    if [ -d "$HOME/.themes/$GTK_THEME_NAME" ] || [ -d "$HOME/.icons/$ICON_THEME_NAME" ]; then
        echo "Themes already installed. Skipping."
        return
    fi

    git clone "$GTK_THEME" "$INSTALL_DIR/Orchis-theme"
    cd "$INSTALL_DIR/Orchis-theme" || exit 1
    yes | ./install.sh -c dark -t teal orange --tweaks black

    git clone "$ICON_THEME" "$INSTALL_DIR/Colloid-icon-theme"
    cd "$INSTALL_DIR/Colloid-icon-theme" || exit 1
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
# Default terminal in sxhkd for now
# ========================================
default_terminal() {
    sudo apt-get -y install rxvt-unicode
}

# ========================================
# Main Execution
# ========================================
echo "Starting full bspwm environment setup..."

install_packages
enable_services
setup_user_dirs
install_reqs
install_wezterm
install_fonts
install_theming
change_theming
default_terminal


echo "🎉 All installations completed successfully!"
