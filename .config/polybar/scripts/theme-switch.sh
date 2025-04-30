#!/bin/bash

# Theme toggle script for polybar
# Toggles between light and dark themes and changes wallpaper randomly
# Creates proportionally smaller wallpapers centered on pure white/black backgrounds

# Define paths
CONFIG_DIR="$HOME/.config/polybar"
STATE_FILE="$CONFIG_DIR/theme_state"
LAST_LIGHT_WALLPAPER_FILE="$CONFIG_DIR/last_light_wallpaper"
LAST_DARK_WALLPAPER_FILE="$CONFIG_DIR/last_dark_wallpaper"
POLYBAR_CONFIG="$CONFIG_DIR/config.ini"
TEMP_DIR="/tmp/theme_wallpapers"

# Define wallpaper directories
LIGHT_WALLPAPER_DIR="$HOME/white_goth"
DARK_WALLPAPER_DIR="$HOME/black_goth"

# Define static background colors
LIGHT_BG="#ffffff"  # Pure white
DARK_BG="#000000"   # Pure black

# Create temporary directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Function to get screen resolution
get_screen_resolution() {
    # Get the primary monitor resolution
    local resolution=$(xrandr --current | grep -w "primary" | grep -o "[0-9]\+x[0-9]\+")
    
    if [ -z "$resolution" ]; then
        # If no primary monitor, get the first connected one
        resolution=$(xrandr --current | grep " connected" | head -n 1 | grep -o "[0-9]\+x[0-9]\+")
    fi
    
    if [ -z "$resolution" ]; then
        # Default fallback
        echo "1920x1080"
        return
    fi
    
    echo "$resolution"
}

# Function to create wallpaper with small centered image on solid background
create_proportional_wallpaper() {
    local source_image="$1"
    local output_image="$2"
    local bg_color="$3"
    local scale_percent=30  # Scale to 30% of screen size
    
    # Get screen resolution
    local resolution=$(get_screen_resolution)
    local screen_width=$(echo "$resolution" | cut -d'x' -f1)
    local screen_height=$(echo "$resolution" | cut -d'x' -f2)
    
    # Calculate target size (30% of screen)
    local target_width=$((screen_width * scale_percent / 100))
    local target_height=$((screen_height * scale_percent / 100))
    
    # Create temporary files
    local temp_trimmed="$TEMP_DIR/trimmed_temp.png"
    local temp_resized="$TEMP_DIR/resized_temp.png"
    
    # First, trim 3 pixels from all edges
    convert "$source_image" -shave 3x3 "$temp_trimmed"
    
    # Resize image proportionally to fit within target dimensions
    convert "$temp_trimmed" -resize "${target_width}x${target_height}" "$temp_resized"
    
    # Get the size of the resized image
    local resized_size=$(identify -format "%wx%h" "$temp_resized")
    local resized_width=$(echo "$resized_size" | cut -d'x' -f1)
    local resized_height=$(echo "$resized_size" | cut -d'x' -f2)
    
    # Calculate position to center the image
    local pos_x=$(( (screen_width - resized_width) / 2 ))
    local pos_y=$(( (screen_height - resized_height) / 2 ))
    
    # Create background with solid color and place resized image on it
    convert -size "${screen_width}x${screen_height}" "canvas:$bg_color" \
        "$temp_resized" -geometry "+${pos_x}+${pos_y}" -composite "$output_image"
    
    # Clean up temporary files
    rm -f "$temp_trimmed" "$temp_resized"
    
    return 0
}

# Function to get a random wallpaper from a directory, avoiding the last used one
get_random_wallpaper() {
    local dir="$1"
    local last_file="$2"
    local max_attempts=10
    
    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        echo "Error: Wallpaper directory $dir does not exist" >&2
        return 1
    fi
    
    # Find all image files (common formats)
    local all_files=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \))
    
    # Convert to array
    IFS=$'\n' read -rd '' -a files <<< "$all_files"
    
    # Check if files were found
    if [ ${#files[@]} -eq 0 ]; then
        echo "Error: No image files found in $dir" >&2
        return 1
    fi
    
    # If only one file, return it
    if [ ${#files[@]} -eq 1 ]; then
        echo "${files[0]}"
        return 0
    fi
    
    # Read the last used file if it exists
    local last_used=""
    if [ -f "$last_file" ]; then
        last_used=$(cat "$last_file")
    fi
    
    # Try to find a different file than the last used
    local random_file=""
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        # Get a random index
        local random_index=$(( RANDOM % ${#files[@]} ))
        random_file="${files[$random_index]}"
        
        # If we found a different file than last used, break
        if [ "$random_file" != "$last_used" ]; then
            break
        fi
        
        # Increment attempts
        attempts=$((attempts + 1))
    done
    
    # Save this file as the last used
    echo "$random_file" > "$last_file"
    
    echo "$random_file"
}

# Log function for debugging
log_message() {
    echo "[theme-switch] $(date): $1" >> "$CONFIG_DIR/theme_switch.log"
}

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "light" > "$STATE_FILE"
fi

# Read current state
CURRENT_THEME=$(cat "$STATE_FILE")

# Toggle theme
if [ "$CURRENT_THEME" = "light" ]; then
    # Switch to dark theme
    echo "dark" > "$STATE_FILE"
    log_message "Switching to dark theme"
    
    # Update polybar colors
    sed -i 's/background = ${colors.background}/background = ${colors.dark-background}/g' "$POLYBAR_CONFIG"
    sed -i 's/foreground = ${colors.foreground}/foreground = ${colors.dark-foreground}/g' "$POLYBAR_CONFIG"
    sed -i 's/background-alt = ${colors.background-alt}/background-alt = ${colors.dark-background-alt}/g' "$POLYBAR_CONFIG"
    sed -i 's/foreground-alt = ${colors.foreground-alt}/foreground-alt = ${colors.dark-foreground-alt}/g' "$POLYBAR_CONFIG"
    sed -i 's/tray-background = ${colors.background}/tray-background = ${colors.dark-background}/g' "$POLYBAR_CONFIG"
    
    # Get random dark wallpaper (different from the last one used)
    RANDOM_WALLPAPER=$(get_random_wallpaper "$DARK_WALLPAPER_DIR" "$LAST_DARK_WALLPAPER_FILE")
    if [ $? -eq 0 ] && [ -f "$RANDOM_WALLPAPER" ]; then
        log_message "Selected dark wallpaper: $RANDOM_WALLPAPER"
        FINAL_WALLPAPER="$TEMP_DIR/final_dark_wallpaper.png"
        
        # Create proportional wallpaper with black background
        if create_proportional_wallpaper "$RANDOM_WALLPAPER" "$FINAL_WALLPAPER" "$DARK_BG"; then
            # Set as wallpaper
            feh --bg-fill "$FINAL_WALLPAPER"
            log_message "Set dark theme wallpaper successfully"
        else
            log_message "Failed to process dark wallpaper, using solid color"
            feh --bg-fill "$DARK_BG"
        fi
    else
        log_message "Failed to find dark wallpaper, using solid color"
        # Fallback to a solid color if no wallpaper is available
        feh --bg-fill "$DARK_BG"
    fi
else
    # Switch to light theme
    echo "light" > "$STATE_FILE"
    log_message "Switching to light theme"
    
    # Update polybar colors
    sed -i 's/background = ${colors.dark-background}/background = ${colors.background}/g' "$POLYBAR_CONFIG"
    sed -i 's/foreground = ${colors.dark-foreground}/foreground = ${colors.foreground}/g' "$POLYBAR_CONFIG"
    sed -i 's/background-alt = ${colors.dark-background-alt}/background-alt = ${colors.background-alt}/g' "$POLYBAR_CONFIG"
    sed -i 's/foreground-alt = ${colors.dark-foreground-alt}/foreground-alt = ${colors.foreground-alt}/g' "$POLYBAR_CONFIG"
    sed -i 's/tray-background = ${colors.dark-background}/tray-background = ${colors.background}/g' "$POLYBAR_CONFIG"
    
    # Get random light wallpaper (different from the last one used)
    RANDOM_WALLPAPER=$(get_random_wallpaper "$LIGHT_WALLPAPER_DIR" "$LAST_LIGHT_WALLPAPER_FILE")
    if [ $? -eq 0 ] && [ -f "$RANDOM_WALLPAPER" ]; then
        log_message "Selected light wallpaper: $RANDOM_WALLPAPER"
        FINAL_WALLPAPER="$TEMP_DIR/final_light_wallpaper.png"
        
        # Create proportional wallpaper with white background
        if create_proportional_wallpaper "$RANDOM_WALLPAPER" "$FINAL_WALLPAPER" "$LIGHT_BG"; then
            # Set as wallpaper
            feh --bg-fill "$FINAL_WALLPAPER"
            log_message "Set light theme wallpaper successfully"
        else
            log_message "Failed to process light wallpaper, using solid color"
            feh --bg-fill "$LIGHT_BG"
        fi
    else
        log_message "Failed to find light wallpaper, using solid color"
        # Fallback to a solid color if no wallpaper is available
        feh --bg-fill "$LIGHT_BG"
    fi
fi

# Check if theme toggle button is showing the right color
if [ "$CURRENT_THEME" = "light" ]; then
    # We just switched to dark theme, update button to show light color for next toggle
    sed -i 's/content-foreground = ${colors.foreground}/content-foreground = ${colors.dark-foreground}/g' "$POLYBAR_CONFIG"
else
    # We just switched to light theme, update button to show dark color for next toggle
    sed -i 's/content-foreground = ${colors.dark-foreground}/content-foreground = ${colors.foreground}/g' "$POLYBAR_CONFIG"
fi

# Restart polybar to apply changes
killall -q polybar
sleep 0.5
polybar mybar &

log_message "Theme switch complete"
exit 0
