#!/bin/bash

# Define the path to the sources.list file
SOURCE_LIST="/etc/apt/sources.list"

# Check if the sources.list file exists
if [ -f "$SOURCE_LIST" ]; then
    # Remove the existing sources.list file
    rm -f "$SOURCE_LIST"
fi

# Create a new sources.list file with the specified content
cat <<EOL > "$SOURCE_LIST"
deb https://fasttrack.debian.net/debian-fasttrack/ bookworm-fasttrack main contrib non-free
deb https://ftp.debian.org/debian/ bookworm contrib main non-free non-free-firmware
deb https://ftp.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
deb https://ftp.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
deb https://ftp.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
deb https://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
EOL

# Update
sudo apt-get update

# Give feedback to the user
echo "The /etc/apt/sources.list file has been updated successfully."
