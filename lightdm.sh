#!/bin/bash

# Update package list and install necessary packages
sudo apt-get update
sleep 2

sudo apt-=get install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings bspwm

sleep 5

# Enable LightDM
sudo systemctl enable lightdm
sudo systemctl set-default lightdm.target

# Create a LightDM configuration file if it doesn't exist
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [ ! -f "$LIGHTDM_CONF" ]; then
    echo "[Seat:*]" | sudo tee -a "$LIGHTDM_CONF"
    echo "greeter-session=lightdm-gtk-greeter" | sudo tee -a "$LIGHTDM_CONF"
    echo "user-session=bspwm" | sudo tee -a "$LIGHTDM_CONF"
    echo "allow-guest=true" | sudo tee -a "$LIGHTDM_CONF"
else
    echo "LightDM configuration file already exists. Updating configuration."
    sudo sed -i '/\[Seat:\*\]/,/^\[.*\]/ s/^allow-guest=false/allow-guest=true/' "$LIGHTDM_CONF" || echo "allow-guest=true" | sudo tee -a "$LIGHTDM_CONF"
    sudo sed -i '/^greeter-session=/c\greeter-session=lightdm-gtk-greeter' "$LIGHTDM_CONF"
    sudo sed -i '/^user-session=/c\user-session=bspwm' "$LIGHTDM_CONF"
fi

# Set your default user to be displayed
echo "Users to be shown on login screen: $(getent passwd | awk -F: '$3 >= 1000 { print $1 }')"

# Display success message
echo "LightDM, LightDM GTK Greeter, and LightDM GTK Greeter Settings have been installed."
echo "Guest logins have been enabled."
echo "BSPWM has been set as the default session."
echo "Please reboot your system for the changes to take effect."

# Reboot command (optional)
# echo "Rebooting in 5 seconds..."
# sleep 5
# sudo reboot
