#!/bin/bash

echo "Creating missing UI and sound placeholder assets..."
echo "=================================================="

# Create UI assets
mkdir -p assets/ui/buttons
mkdir -p assets/ui/panels
mkdir -p assets/ui/cursors
mkdir -p assets/ui/icons

# Create sound directories
mkdir -p assets/sounds/effects
mkdir -p assets/sounds/music
mkdir -p assets/sounds/ambient

# Function to create a colored rectangle (requires ImageMagick)
create_ui_element() {
    local name=$1
    local width=$2
    local height=$3
    local color=$4
    local path=$5
    
    if command -v convert &> /dev/null; then
        convert -size ${width}x${height} xc:"$color" -bordercolor "#333333" -border 2 "$path/$name.png"
        echo "  ✓ Created $name.png"
    else
        echo "  ! ImageMagick not found. Creating placeholder text for $name"
        echo "UI Element: $name (${width}x${height}, color: $color)" > "$path/$name.txt"
    fi
}

echo ""
echo "Creating UI Buttons..."
create_ui_element "button_normal" 200 50 "#5a5a5a" "assets/ui/buttons"
create_ui_element "button_hover" 200 50 "#7a7a7a" "assets/ui/buttons"
create_ui_element "button_pressed" 200 50 "#3a3a3a" "assets/ui/buttons"
create_ui_element "button_disabled" 200 50 "#2a2a2a" "assets/ui/buttons"

# Small icon buttons
create_ui_element "icon_button_normal" 40 40 "#4a4a4a" "assets/ui/buttons"
create_ui_element "icon_button_hover" 40 40 "#6a6a6a" "assets/ui/buttons"

echo ""
echo "Creating UI Panels..."
create_ui_element "panel_background" 300 400 "#2d2d2d" "assets/ui/panels"
create_ui_element "dialog_background" 600 200 "#1a1a1a" "assets/ui/panels"
create_ui_element "tooltip_background" 200 60 "#000000" "assets/ui/panels"
create_ui_element "inventory_slot" 64 64 "#3d3d3d" "assets/ui/panels"

echo ""
echo "Creating UI Cursors..."
# Create cursor placeholder files
if command -v convert &> /dev/null; then
    # Default cursor (arrow)
    convert -size 32x32 xc:transparent \
        -fill white -draw "polygon 0,0 0,20 14,14 20,0" \
        -stroke black -strokewidth 1 -draw "polygon 0,0 0,20 14,14 20,0" \
        assets/ui/cursors/cursor_default.png
    echo "  ✓ Created cursor_default.png"
    
    # Hand cursor
    convert -size 32x32 xc:transparent \
        -fill white -draw "circle 16,16 16,8" \
        -stroke black -strokewidth 1 -draw "circle 16,16 16,8" \
        assets/ui/cursors/cursor_hand.png
    echo "  ✓ Created cursor_hand.png"
    
    # Look cursor (eye)
    convert -size 32x32 xc:transparent \
        -fill white -draw "ellipse 16,16 12,8 0,360" \
        -fill black -draw "circle 16,16 16,12" \
        assets/ui/cursors/cursor_look.png
    echo "  ✓ Created cursor_look.png"
else
    echo "cursor_default (32x32) - Arrow pointer" > assets/ui/cursors/cursor_default.txt
    echo "cursor_hand (32x32) - Hand/grab pointer" > assets/ui/cursors/cursor_hand.txt
    echo "cursor_look (32x32) - Eye/examine pointer" > assets/ui/cursors/cursor_look.txt
fi

echo ""
echo "Creating UI Icons..."
create_ui_element "icon_save" 24 24 "#4CAF50" "assets/ui/icons"
create_ui_element "icon_load" 24 24 "#2196F3" "assets/ui/icons"
create_ui_element "icon_new" 24 24 "#FFC107" "assets/ui/icons"
create_ui_element "icon_delete" 24 24 "#F44336" "assets/ui/icons"
create_ui_element "icon_settings" 24 24 "#9E9E9E" "assets/ui/icons"

# Tool icons
create_ui_element "tool_select" 32 32 "#FF9800" "assets/ui/icons"
create_ui_element "tool_move" 32 32 "#03A9F4" "assets/ui/icons"
create_ui_element "tool_place" 32 32 "#4CAF50" "assets/ui/icons"
create_ui_element "tool_delete" 32 32 "#F44336" "assets/ui/icons"
create_ui_element "tool_paint" 32 32 "#E91E63" "assets/ui/icons"
create_ui_element "tool_zoom" 32 32 "#9C27B0" "assets/ui/icons"

echo ""
echo "Creating placeholder sound files..."
# Create placeholder text files for sounds
cat > assets/sounds/sound_credits.txt << EOF
PLACEHOLDER SOUND FILES
======================

These are placeholder references for sound effects.
For actual sounds, consider these CC0/Public Domain sources:

SOUND EFFECTS:
- Freesound.org (filter by CC0)
- OpenGameArt.org (audio section)
- Zapsplat.com (free with account)
- SoundBible.com (public domain section)

MUSIC:
- Kevin MacLeod (incompetech.com) - CC-BY
- OpenGameArt.org (music section)
- FreePD.com - Public domain music
- Bensound.com - Free music

RECOMMENDED SOUNDS FOR POINT & CLICK:
EOF

# Effects placeholders
effects=(
    "click.ogg:UI button click sound"
    "hover.ogg:UI element hover sound"
    "pickup.ogg:Item pickup sound"
    "door_open.ogg:Door opening sound"
    "door_close.ogg:Door closing sound"
    "footstep_1.ogg:Footstep sound variant 1"
    "footstep_2.ogg:Footstep sound variant 2"
    "success.ogg:Success/achievement sound"
    "error.ogg:Error/invalid action sound"
    "dialog_open.ogg:Dialog window open"
    "dialog_close.ogg:Dialog window close"
)

echo "" >> assets/sounds/sound_credits.txt
echo "EFFECTS (/assets/sounds/effects/):" >> assets/sounds/sound_credits.txt
for effect in "${effects[@]}"; do
    IFS=':' read -r filename description <<< "$effect"
    echo "$filename - $description" > "assets/sounds/effects/${filename%.ogg}.txt"
    echo "- $filename: $description" >> assets/sounds/sound_credits.txt
done

# Music placeholders
music=(
    "main_theme.ogg:Main menu theme music"
    "village_ambient.ogg:Village background music"
    "forest_ambient.ogg:Forest area music"
    "castle_ambient.ogg:Castle area music"
    "tension.ogg:Suspenseful moment music"
    "victory.ogg:Success/completion music"
)

echo "" >> assets/sounds/sound_credits.txt
echo "MUSIC (/assets/sounds/music/):" >> assets/sounds/sound_credits.txt
for track in "${music[@]}"; do
    IFS=':' read -r filename description <<< "$track"
    echo "$filename - $description" > "assets/sounds/music/${filename%.ogg}.txt"
    echo "- $filename: $description" >> assets/sounds/sound_credits.txt
done

# Ambient sounds
ambient=(
    "birds.ogg:Bird chirping ambient loop"
    "wind.ogg:Wind blowing ambient loop"
    "fire_crackling.ogg:Fireplace crackling loop"
    "water_flow.ogg:River/stream flowing loop"
    "crowd_chatter.ogg:Background crowd noise"
)

echo "" >> assets/sounds/sound_credits.txt
echo "AMBIENT (/assets/sounds/ambient/):" >> assets/sounds/sound_credits.txt
for sound in "${ambient[@]}"; do
    IFS=':' read -r filename description <<< "$sound"
    echo "$filename - $description" > "assets/sounds/ambient/${filename%.ogg}.txt"
    echo "- $filename: $description" >> assets/sounds/sound_credits.txt
done

echo "  ✓ Created sound placeholder files and credits"

# Update the main assets index
echo ""
echo "Updating assets index..."
cat >> assets/assets_index.txt << EOF

UI (/assets/ui/)
----------------
Buttons (/buttons/)
- button_normal.png - Normal button state
- button_hover.png - Button hover state
- button_pressed.png - Button pressed state
- button_disabled.png - Disabled button state
- icon_button_normal.png - Small icon button
- icon_button_hover.png - Small icon button hover

Panels (/panels/)
- panel_background.png - Generic panel background
- dialog_background.png - Dialog box background
- tooltip_background.png - Tooltip background
- inventory_slot.png - Inventory slot background

Cursors (/cursors/)
- cursor_default.png - Default arrow cursor
- cursor_hand.png - Interactive/grab cursor
- cursor_look.png - Examine/look cursor

Icons (/icons/)
- icon_save.png - Save icon
- icon_load.png - Load icon
- icon_new.png - New/create icon
- icon_delete.png - Delete/trash icon
- icon_settings.png - Settings/gear icon
- tool_select.png - Selection tool icon
- tool_move.png - Move tool icon
- tool_place.png - Place tool icon
- tool_delete.png - Delete tool icon
- tool_paint.png - Paint tool icon
- tool_zoom.png - Zoom tool icon

SOUNDS (/assets/sounds/)
------------------------
See sound_credits.txt for detailed sound file descriptions and sources.

Effects (/effects/) - UI and gameplay sound effects
Music (/music/) - Background music tracks
Ambient (/ambient/) - Environmental ambient loops
EOF

echo "  ✓ Updated assets index"

echo ""
echo "=== SUMMARY ==="
echo "Created placeholder assets for:"
echo "- UI buttons (6 files)"
echo "- UI panels (4 files)"
echo "- UI cursors (3 files)"
echo "- UI icons (11 files)"
echo "- Sound placeholders (22 files)"
echo ""
echo "To use real assets:"
echo "1. Replace PNG files with actual graphics"
echo "2. Download CC0 sounds from the sources listed in sound_credits.txt"
echo "3. Ensure all assets match the expected dimensions"
echo ""
echo "Done!"