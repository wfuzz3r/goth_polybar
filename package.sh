#!/bin/bash

# Script to package all necessary polybar files and wallpapers for sharing

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Packaging Polybar Configuration       ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p .config/polybar/scripts
mkdir -p wallpapers/black_goth
mkdir -p wallpapers/white_goth
mkdir -p screenshots

# Copy polybar configuration
echo -e "${YELLOW}Copying polybar configuration files...${NC}"
cp -f ~/.config/polybar/config.ini .config/polybar/
cp -f ~/.config/polybar/scripts/*.sh .config/polybar/scripts/

# Copy wallpapers
echo -e "${YELLOW}Copying wallpapers...${NC}"
cp -f ~/black_goth/* wallpapers/black_goth/ 2>/dev/null
cp -f ~/white_goth/* wallpapers/white_goth/ 2>/dev/null

# Take screenshots if scrot is available
if command -v scrot &> /dev/null; then
    echo -e "${YELLOW}Taking screenshots for README...${NC}"
    # Let the user know to switch to dark theme for screenshot
    echo -e "${YELLOW}Please switch to DARK theme and press Enter to take screenshot...${NC}"
    read -p ""
    scrot -u screenshots/dark_theme.png
    
    # Let the user know to switch to light theme for screenshot
    echo -e "${YELLOW}Please switch to LIGHT theme and press Enter to take screenshot...${NC}"
    read -p ""
    scrot -u screenshots/light_theme.png
else
    echo -e "${YELLOW}scrot not installed. Please add screenshots manually.${NC}"
    touch screenshots/.gitkeep
fi

# Create tar archive
echo -e "${YELLOW}Creating archive...${NC}"
tar -czvf polybar-goth-theme.tar.gz .config wallpapers README.md install.sh screenshots

echo ""
echo -e "${GREEN}Package created: polybar-goth-theme.tar.gz${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Share this file to distribute your polybar configuration.${NC}"
echo -e "${BLUE}========================================${NC}"

exit 0

