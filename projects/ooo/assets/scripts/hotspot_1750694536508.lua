-- Script for hotspot: hotspot_1750694536508
-- This script handles interactions with the hotspot_1750694536508 hotspot

function on_click()
    -- Called when the hotspot is clicked
    show_message("You clicked on hotspot_1750694536508")
end

function on_hover()
    -- Called when the mouse hovers over the hotspot
    -- set_cursor("hand")
end

function on_use_item(item_name)
    -- Called when an inventory item is used on this hotspot
    show_message("You used " .. item_name .. " on hotspot_1750694536508")
end
