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
# User Confirmation Before Proceeding
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

# Cleanup function
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
# Move Config Files to ~/.config/bspwm
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
# Package Installation Section
# ========================================
# Install required packages
install_packages() {
    echo "Installing required packages..."
    sudo apt-get install -y xorg xorg-dev xbacklight xbindkeys xvkbd xinput build-essential bspwm sxhkd polybar network-manager-gnome pamixer 
    sudo apt get instal  -y nemo lxappearance dialog mtools avahi-daemon acpi acpid gvfs-backends gnome-power-manager pavucontrol pulsemixer 
    sudo apt-get install -y feh fonts-recommended fonts-font-awesome fonts-terminus exa suckless-tools viewnior rofi dunst playerctl brightnessctl wmctrl
    sudo apt-get install -y libnotify-bin xdotool unzip libnotify-dev pipewire-audio nala micro xdg-user-dirs-gtk terminator lightdm || echo "Warning: Package installation failed."
    echo "Package installation completed."
}

# ========================================
# Enabling Required Services
# ========================================
# Enables system services such as Avahi and ACPI
# ------------------------------------------------
# This section ensures that necessary services like Avahi (for network discovery)
# and ACPI (for power management) are enabled on the system for proper operation.
enable_services() {
    echo "Enabling required services..."
    sudo systemctl enable avahi-daemon || echo "Warning: Failed to enable avahi-daemon."
    sudo systemctl enable acpid || echo "Warning: Failed to enable acpid."
    echo "Services enabled."
}

# ========================================
# User Directory Setup
# ========================================
# Sets up user directories (e.g., Downloads, Music, Pictures) and creates
# a Screenshots folder for easy screenshot management
# ---------------------------------------------------------------
# This section updates the user directories (such as `Downloads` or `Documents`) 
# using the `xdg-user-dirs-update` utility. It also ensures a `Screenshots` 
# directory exists in the user's home directory for managing screenshots.
setup_user_dirs() {
    echo "Updating user directories..."
    xdg-user-dirs-update || echo "Warning: Failed to update user directories."
    mkdir -p ~/Screenshots/ || echo "Warning: Failed to create Screenshots directory."
    echo "User directories updated."
}
# ========================================
# Utility Functions
# ========================================
command_exists() {
    command -v "$1" &>/dev/null
}

install_reqs() {
    echo "Updating package lists and installing required dependencies..."
    sudo apt-get install -y cmake meson ninja-build curl pkg-config || { echo "Package installation failed."; exit 1; }
}

# ========================================
# Picom Installation
# ========================================
install_ftlabs_picom() {
	if command_exists picom; then
        echo "Picom is already installed. Skipping installation."
        return
    fi
	sudo apt-get install -y libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev libpixman-1-dev 
	sudo apt-get install -y	libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-dpms0-dev libxcb-glx0-dev
    sudo apt-get install -y libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev 
    sudo apt-get install -y libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev libxext-dev uthash-dev wget curl xd jq xsettingsd
    sudo apt-get install -y inxi xinit

mkdir -p ~/.config/rofi
rofi -dump-config > ~/.config/rofi/config.rasi
mkdir -p ~/.config/rofi/themes
mkdir -p ~/.config/rofi/scripts # add to path
mkdir -p ~/.config/rofi/bin # add to path

	
    git clone https://github.com/FT-Labs/picom "$INSTALL_DIR/picom" || die "Failed to clone Picom."
    cd "$INSTALL_DIR/picom"
    meson setup --buildtype=release build
    ninja -C build
    sudo ninja -C build install
}

# ========================================
# Fastfetch Installation
# ========================================
install_fastfetch() {
	if command_exists fastfetch; then
        echo "Fastfetch is already installed. Skipping installation."
        return
    fi	
	
    echo "Installing Fastfetch..."
    git clone https://github.com/fastfetch-cli/fastfetch "$INSTALL_DIR/fastfetch" || { echo "Failed to clone Fastfetch repository."; return 1; }
    cd "$INSTALL_DIR/fastfetch" || { echo "Failed to access Fastfetch directory."; return 1; }
    cmake -S . -B build || { echo "CMake configuration failed."; return 1; }
    cmake --build build || { echo "Build process failed."; return 1; }
    sudo mv build/fastfetch /usr/local/bin/ || { echo "Failed to move Fastfetch binary to /usr/local/bin/."; return 1; }
    echo "Fastfetch installation complete."
    
	echo "Setting up fastfetch configuration..."
	
	# Ensure the target directory exists
	mkdir -p "$HOME/.config/fastfetch"
	
	# Move the folder into place
	mv .config/fastfetch "$HOME/.config/"
	
	echo "Fastfetch configuration setup complete."
   
}

# ============================================
# Install Wezterm
# ============================================
install_wezterm() {
    if command_exists wezterm; then
        echo "Wezterm is already installed. Skipping installation."
        return
    fi

    echo "Installing Wezterm..."

    WEZTERM_URL="https://github.com/wezterm/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203-110809-5046fc22.Debian12.deb"
    TMP_DEB="/tmp/wezterm.deb"

    wget -O "$TMP_DEB" "$WEZTERM_URL" || die "Failed to download Wezterm."
    sudo apt install -y "$TMP_DEB" || die "Failed to install Wezterm."
    rm -f "$TMP_DEB"

    echo "Setting up Wezterm configuration..."
    mkdir -p "$HOME/.config/wezterm"
    wget -O "$HOME/.config/wezterm/wezterm.lua" "" || die "Failed to download wezterm config."

    echo "Wezterm installation and configuration complete."
}


# ========================================
# Font Installation
# ========================================
# Installs a list of selected fonts for better terminal and GUI appearance
# ----------------------------------------------------------------------
# This section installs various fonts including `Nerd Fonts` from GitHub releases,
# and copies custom TTF fonts into the local fonts directory. It then rebuilds 
# the font cache using `fc-cache`.
install_fonts() {
    echo "Installing fonts..."

    mkdir -p ~/.local/share/fonts

    fonts=( "FiraCode" "Hack" "JetBrainsMono" "RobotoMono" "SourceCodePro" "UbuntuMono" )

    for font in "${fonts[@]}"; do
        if ls ~/.local/share/fonts/$font/*.ttf &>/dev/null; then
            echo "Font $font is already installed. Skipping."
        else
            echo "Installing font: $font"
            wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$font.zip" -P /tmp || {
                echo "Warning: Error downloading font $font."
                continue
            }
            unzip -q /tmp/$font.zip -d ~/.local/share/fonts/$font/ || {
                echo "Warning: Error extracting font $font."
                continue
            }
            rm /tmp/$font.zip
        fi
    done

    # Refresh font cache
    fc-cache -f || echo "Warning: Error rebuilding font cache."

    echo "Font installation completed."
}

# ========================================
# GTK Theme Installation
# ========================================
install_theming() {
    GTK_THEME_NAME="Orchis-Teal-Dark"
    ICON_THEME_NAME="Colloid-Teal-Everforest-Dark"

    if [ -d "$HOME/.themes/$GTK_THEME_NAME" ] || [ -d "$HOME/.icons/$ICON_THEME_NAME" ]; then
        echo "One or more themes/icons already installed. Skipping theming installation."
        return
    fi

    echo "Installing GTK and Icon themes..."

    # GTK Theme Installation
    git clone "$GTK_THEME" "$INSTALL_DIR/Orchis-theme" || die "Failed to clone Orchis theme."
    cd "$INSTALL_DIR/Orchis-theme" || die "Failed to enter Orchis theme directory."
    yes | ./install.sh -c dark -t teal orange --tweaks black

    # Icon Theme Installation
    git clone "$ICON_THEME" "$INSTALL_DIR/Colloid-icon-theme" || die "Failed to clone Colloid icon theme."
    cd "$INSTALL_DIR/Colloid-icon-theme" || die "Failed to enter Colloid icon theme directory."
    ./install.sh -t teal orange -s default gruvbox everforest

    echo "Theming installation complete."
}

# ========================================
# GTK Theme Settings
# ========================================

change_theming() {
# Ensure the directories exist
mkdir -p ~/.config/gtk-3.0

# Write to ~/.config/gtk-3.0/settings.ini
cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Orchis-Teal-Dark
gtk-icon-theme-name=Colloid-Teal-Everforest-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

# Write to ~/.gtkrc-2.0
cat << EOF > ~/.gtkrc-2.0
gtk-theme-name="Orchis-Teal-Dark"
gtk-icon-theme-name="Colloid-Teal-Everforest-Dark"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
EOF

echo "GTK settings updated."


# ========================================
# Main Script Execution
# ========================================
echo "Starting installation process..."

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

set terminator as default terminal in sxhkd

echo "All installations completed successfully!"

ask user if the want to install lightdm
if yes chmod +x lightdm.sh
# then install
./lightdm.shif no exit
