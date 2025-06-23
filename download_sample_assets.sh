#!/bin/bash

# Create sample assets directory
mkdir -p sample_assets/backgrounds
mkdir -p sample_assets/characters
mkdir -p sample_assets/ui

echo "Downloading sample CC0 assets for testing..."
echo "==========================================="
echo ""
echo "Note: These are placeholder assets for testing."
echo "For real projects, download assets from:"
echo "- OpenGameArt.org (CC0 collections)"
echo "- Itch.io (CC0 game assets)"
echo "- Kenney.nl (Public domain assets)"
echo ""

# Create some placeholder colored backgrounds for testing
echo "Creating placeholder backgrounds..."
for color in "forest_green:34,139,34" "castle_gray:105,105,105" "village_brown:139,69,19" "ocean_blue:0,119,190"; do
    name=$(echo $color | cut -d: -f1)
    rgb=$(echo $color | cut -d: -f2)
    echo "  - ${name}.png"
    # Using ImageMagick if available, otherwise create a note
    if command -v convert &> /dev/null; then
        convert -size 800x600 xc:rgb\($rgb\) sample_assets/backgrounds/${name}.png
    else
        echo "ImageMagick not found. Please create ${name}.png manually (800x600, RGB: $rgb)" > sample_assets/backgrounds/${name}.txt
    fi
done

echo ""
echo "Creating placeholder character sprites..."
for char in "hero" "villain" "npc_merchant" "npc_guard"; do
    echo "  - ${char}.png"
    if command -v convert &> /dev/null; then
        # Create a simple colored rectangle as placeholder
        convert -size 64x128 xc:rgba\(255,255,255,0.8\) -fill black -annotate +10+64 "$char" sample_assets/characters/${char}.png
    else
        echo "Placeholder for $char character sprite (64x128)" > sample_assets/characters/${char}.txt
    fi
done

echo ""
echo "Creating UI elements..."
for ui in "button_normal" "button_hover" "panel_bg"; do
    echo "  - ${ui}.png"
    if command -v convert &> /dev/null; then
        convert -size 200x50 xc:rgba\(100,100,100,0.9\) sample_assets/ui/${ui}.png
    else
        echo "Placeholder for $ui UI element" > sample_assets/ui/${ui}.txt
    fi
done

echo ""
echo "Sample assets created in ./sample_assets/"
echo ""
echo "To use real assets:"
echo "1. Visit https://opengameart.org/content/cc0-resources"
echo "2. Download CC0 licensed sprites and backgrounds"
echo "3. Place them in your project's assets folder"
echo ""
echo "Recommended CC0 asset packs:"
echo "- Kenney Game Assets: https://kenney.nl/assets"
echo "- LPC (Liberated Pixel Cup) assets on OpenGameArt"
echo "- Pixel Adventure assets on itch.io"