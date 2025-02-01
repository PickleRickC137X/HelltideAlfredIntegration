local menu = require("menu")
local maidenmain = require("data.maidenmain")

local menu_renderer = {}

local function safe_render(menu_item, label, description, value)
    if type(value) == "boolean" then
        value = value and 1 or 0
    elseif type(value) ~= "number" then
        value = 0
    end
    menu_item:render(label, description, value)
end

function menu_renderer.render_menu(plugin_enabled, open_doors_enabled, loop_enabled, revive_enabled, indent)
    if not menu.main_tree:push("Helltide Farmer (EletroLuz)-V3.0") then
        return
    end

    -- Render movement plugin
    menu.plugin_enabled:render("Enable Plugin Chests Farm", "Enable or disable the chest farm plugin", 0)

    -- Render o checkbox enable open chests
    menu.main_openDoors_enabled:render("Open Chests", "Enable or disable the chest plugin", 0)

    -- Render checkbox loop
    menu.loop_enabled:render("Enable Loop", "Enable or disable looping waypoints", 0)

    -- Render revive
    menu.revive_enabled:render("Enable Revive Module", "Enable or disable the revive module", 0)

    -- Subsection Move Threshold
    if menu.move_threshold_tree:push("Chest Move Range Settings") then
        menu.move_threshold_slider:render("Move Threshold", "Set Chest Max Move distance", 2)
        menu.move_threshold_tree:pop()
    end

    -- Subsection Maiden Farmer
    if menu.maiden_tree:push("Maiden Farmer Settings") then
        menu.main_helltide_maiden_auto_plugin_enabled:render("Enable Maiden Farmer", "Enable or disable the Maiden farmer", 0)
        menu.main_helltide_maiden_duration:render("Maiden Duration (minutes)", "Duration of Maiden farming before switching to chests", 0)
        menu.maiden_tree:pop()
    end

    -- Subsection Vendor Manager (Alfred)
    if menu.vendor_manager_tree:push("Alfred Vendor Manager") then
        menu.vendor_enabled:render("Enable Alfred Vendor Manager", "Enable or disable Alfred's vendor management", 0)
        menu.auto_return:render("Auto Return After Vendor", "Automatically return to previous location after vendor visit", 0)
        menu.enable_during_helltide:render("Enable During Helltide", "Allow Alfred to manage inventory during Helltide", 0)
        menu.vendor_manager_tree:pop()
    end

    menu.main_tree:pop()
end

return menu_renderer