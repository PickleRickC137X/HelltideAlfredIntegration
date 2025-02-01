local plugin_label = "CAMINHADOR_PLUGIN_"

local menu_elements = 
{
    main_tree = tree_node:new(0),
    plugin_enabled = checkbox:new(false, get_hash(plugin_label .. "plugin_enabled")),
    main_openDoors_enabled = checkbox:new(false, get_hash(plugin_label .. "main_openDoors_enabled")),
    loop_enabled = checkbox:new(false, get_hash(plugin_label .. "loop_enabled")),
    revive_enabled = checkbox:new(false, get_hash(plugin_label .. "revive_enabled")),
        
    -- Subsection Move Threshold
    move_threshold_tree = tree_node:new(2),
    move_threshold_slider = slider_int:new(12, 20, 12, get_hash(plugin_label .. "move_threshold_slider")),

    -- Subsection Maiden Farmer
    maiden_tree = tree_node:new(3),
    main_helltide_maiden_auto_plugin_enabled = checkbox:new(false, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_enabled")),
    main_helltide_maiden_duration = slider_float:new(1.0, 60.0, 30.0, get_hash(plugin_label .. "main_helltide_maiden_duration")),
    main_helltide_maiden_auto_plugin_run_explorer = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_run_explorer")),
    main_helltide_maiden_auto_plugin_auto_revive = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_auto_revive")),
    main_helltide_maiden_auto_plugin_show_task = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_show_task")),
    main_helltide_maiden_auto_plugin_show_explorer_circle = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_show_explorer_circle")),
    main_helltide_maiden_auto_plugin_run_explorer_close_first = checkbox:new(true, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_run_explorer_close_first")),
    main_helltide_maiden_auto_plugin_explorer_threshold = slider_float:new(0.0, 20.0, 1.5, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_explorer_threshold")),
    main_helltide_maiden_auto_plugin_explorer_thresholdvar = slider_float:new(0.0, 10.0, 3.0, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_explorer_thresholdvar")),
    main_helltide_maiden_auto_plugin_explorer_circle_radius = slider_float:new(5.0, 30.0, 15.0, get_hash(plugin_label .. "main_helltide_maiden_auto_plugin_explorer_circle_radius")),

    -- Subsection Vendor Manager (Alfred)
    vendor_manager_tree = tree_node:new(4),
    vendor_enabled = checkbox:new(false, get_hash("VENDOR_MANAGER_enabled")),
    auto_return = checkbox:new(true, get_hash(plugin_label .. "auto_return")),
    enable_during_helltide = checkbox:new(false, get_hash("VENDOR_MANAGER_during_helltide"))
}

menu_elements.render_menu = function()
    menu_elements.main_tree:push("Helltide Farmer (EletroLuz)-V3.0")

    -- Render movement plugin
    menu_elements.plugin_enabled:render("Enable Plugin Chests Farm", "Enable or disable the chest farm plugin")

    -- Render o checkbox enable open chests
    menu_elements.main_openDoors_enabled:render("Open Chests", "Enable or disable the chest plugin")

    -- Render checkbox loop
    menu_elements.loop_enabled:render("Enable Loop", "Enable or disable looping waypoints")

    -- Render revive
    menu_elements.revive_enabled:render("Enable Revive Module", "Enable or disable the revive module")

    -- Subsection Move Threshold
    if menu_elements.move_threshold_tree:push("Chest Move Range Settings") then
        menu_elements.move_threshold_slider:render("Move Threshold", "Set Chest Max Move distance")
        menu_elements.move_threshold_tree:pop()
    end

    -- Subsection Maiden Farmer
    if menu_elements.maiden_tree:push("Maiden Farmer Settings") then
        menu_elements.main_helltide_maiden_auto_plugin_enabled:render("Enable Maiden Farmer", "Enable or disable the Maiden farmer", 0, 0)
        menu_elements.main_helltide_maiden_duration:render("Maiden Duration (minutes)", "Duration of Maiden farming before switching to chests", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_run_explorer:render("Run Explorer", "Enable or disable explorer for Maiden", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_auto_revive:render("Auto Revive", "Enable or disable auto revive for Maiden", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_show_task:render("Show Task", "Show current Maiden task", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_show_explorer_circle:render("Show Explorer Circle", "Show explorer circle for Maiden", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_run_explorer_close_first:render("Run Explorer Close First", "Run explorer on closest targets first", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_explorer_threshold:render("Explorer Threshold", "Set explorer threshold distance", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_explorer_thresholdvar:render("Explorer Threshold Variance", "Set explorer threshold variance", 0, 0)
        menu_elements.main_helltide_maiden_auto_plugin_explorer_circle_radius:render("Explorer Circle Radius", "Set explorer circle radius", 0, 0)
        menu_elements.maiden_tree:pop()
    end

    -- Subsection Vendor Manager (Alfred)
    if menu_elements.vendor_manager_tree:push("Alfred Vendor Manager") then
        menu_elements.vendor_enabled:render("Enable Alfred Vendor Manager", "Enable or disable Alfred's vendor management")
        menu_elements.auto_return:render("Auto Return After Vendor", "Automatically return to previous location after vendor visit")
        menu_elements.enable_during_helltide:render("Enable During Helltide", "Allow Alfred to manage inventory during Helltide")
        menu_elements.vendor_manager_tree:pop()
    end

    menu_elements.main_tree:pop()
end

return menu_elements