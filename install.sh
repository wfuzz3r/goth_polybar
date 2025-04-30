#!/bin/bash

# Polybar Configuration Installation Script
# This script installs the custom polybar configuration with theme switching

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Polybar Theme Switcher Installation   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check for dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

# Array of required dependencies
DEPENDENCIES=("polybar" "feh" "convert" "i3")
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v $dep &> /dev/null; then
        MISSING_DEPS+=($dep)
    fi
done

# Font dependencies
if [ ! -d "/usr/share/fonts/truetype/font-awesome" ] && [ ! -d "/usr/share/fonts/TTF/font-awesome" ]; then
    MISSING_DEPS+=("fonts-font-awesome")
fi

# Check if any dependencies are missing
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Please install them with:${NC}"
    echo -e "sudo apt install ${MISSING_DEPS[*]}"
    
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}All dependencies are installed.${NC}"
fi

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p ~/.config/polybar/scripts
mkdir -p ~/black_goth ~/white_goth

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
cp -f .config/polybar/config.ini ~/.config/polybar/
cp -f .config/polybar/scripts/* ~/.config/polybar/scripts/
chmod +x ~/.config/polybar/scripts/*.sh

# Copy wallpapers
echo -e "${YELLOW}Copying wallpapers...${NC}"
cp -r wallpapers/black_goth/* ~/black_goth/ 2>/dev/null
cp -r wallpapers/white_goth/* ~/white_goth/ 2>/dev/null

# Check if i3 is configured for polybar
echo -e "${YELLOW}Checking i3 configuration...${NC}"
I3_CONFIG="$HOME/.config/i3/config"

if [ -f "$I3_CONFIG" ]; then
    if ! grep -q "polybar/scripts/launch.sh" "$I3_CONFIG"; then
        echo -e "${YELLOW}Adding polybar to i3 startup...${NC}"
        echo -e "\n# Start polybar\nexec_always --no-startup-id ~/.config/polybar/scripts/launch.sh" >> "$I3_CONFIG"
    else
        echo -e "${GREEN}Polybar already in i3 startup config.${NC}"
    fi
else
    echo -e "${RED}i3 config file not found at $I3_CONFIG${NC}"
    echo -e "${YELLOW}Please add the following line to your i3 config:${NC}"
    echo 'exec_always --no-startup-id ~/.config/polybar/scripts/launch.sh'
fi

# Initialize state files if needed
touch ~/.config/polybar/theme_state
echo "light" > ~/.config/polybar/theme_state
touch ~/.config/polybar/last_light_wallpaper
touch ~/.config/polybar/last_dark_wallpaper

# Launch polybar
echo -e "${YELLOW}Starting polybar...${NC}"
~/.config/polybar/scripts/launch.sh &

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}To toggle themes:${NC} Click the circle icon on polybar"
echo -e "${YELLOW}To customize:${NC} Edit ~/.config/polybar/config.ini"
echo -e "${YELLOW}To add wallpapers:${NC} Add images to ~/black_goth or ~/white_goth"
echo -e "${BLUE}========================================${NC}"

exit 0

