local menu = require("menu")
local enums = require("data.enums")
local BossMaterialsService = require("services.boss_materials_service")
local StashService = require("services.stash_service")
local SalvageService = require("services.salvage_service")
local SellService = require("services.sell_service")
local RepairService = require("services.repair_service")
local PortalService = require("services.portal_service")
local vendor_teleport = require("data.vendor_teleport")
local GameStateChecker = require("functions.game_state_checker")
local maidenmain = require("data.maidenmain")

local screen_message = ""
local screen_message_time = 0
local SCREEN_MESSAGE_DURATION = 20
local color_white = color.new(255, 255, 255, 255)

local InventoryManager = {
    CONSTANTS = {
        VENDOR_CHECK_INTERVAL = 5, 
        INTERACTION_DISTANCE = 3.0,
        MOVEMENT_THRESHOLD = 2.5,
        TELEPORT_CHECK_INTERVAL = 1,
        ACTION_DELAY = 0.5,
        MAX_RETRIES = 5,  
        HELLTIDE_CHECK_INTERVAL = 2 
    },

    state = {
        is_processing = false,
        current_target = nil,
        last_check_time = 0,
        last_action_time = 0,
        current_action = nil,
        retries = 0,
        last_helltide_check = 0,
        last_teleport_check = 0,
        waiting_for_teleport = false,
        teleport_completed = false,
        portal_target = nil,
        active_plugin = nil,
        original_plugin = nil,
        portal_used = false
    }
}

local function set_screen_message(message)
    screen_message = message
    screen_message_time = get_time_since_inject()
end

function InventoryManager.draw_screen_message()
    if screen_message ~= "" then
        local current_time = get_time_since_inject()
        if current_time - screen_message_time < SCREEN_MESSAGE_DURATION then
            graphics.text_2d(screen_message, vec2:new(600, 350), 20, color_white)
        else
            screen_message = ""
        end
    end
end

-- Função para salvar qual plugin está ativo
function InventoryManager:save_active_plugin()
    if maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:get() then
        self.state.original_plugin = "maiden"
        console.print("DEBUG: Saving original state: Plugin Maiden")
    elseif menu.plugin_enabled:get() then
        self.state.original_plugin = "chest"
        console.print("DEBUG: Saving original state: Plugin Chest")
    end
    console.print("DEBUG: Original state saved: " .. tostring(self.state.original_plugin))
end

-- Função para restaurar o plugin original
function InventoryManager:restore_original_plugin()
    console.print("DEBUG: Trying to restore plugin: " .. tostring(self.state.original_plugin))
    if self.state.original_plugin == "maiden" then
        console.print("DEBUG: Restoring Maiden")
        maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:set(true)
        menu.plugin_enabled:set(false)
    else
        console.print("DEBUG: Restoring Chest")
        maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:set(false)
        menu.plugin_enabled:set(true)
    end
end

-- Adicionar esta função para gerenciar os plugins
function InventoryManager:set_plugin_state(enable)
    if self.state.active_plugin == "maiden" then
        maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:set(enable)
    else
        menu.plugin_enabled:set(enable)
    end
end

-- Adicionar esta função para verificar qual plugin está ativo
function InventoryManager:update_active_plugin()
    if maidenmain.menu_elements.main_helltide_maiden_auto_plugin_enabled:get() then
        self.state.active_plugin = "maiden"
    elseif menu.plugin_enabled:get() then
        self.state.active_plugin = "chest"
    end
end

function InventoryManager:ensure_explorer_disabled()
    if explorer and explorer.is_enabled() then
        console.print("Disabling explorer that was incorrectly active")
        explorer.disable()
    end
end

function InventoryManager:handle_helltide_vendor()
    console.print("==== Debug Helltide Vendor ====")
    console.print("Enable During Helltide: " .. tostring(menu.enable_during_helltide:get()))
    
    local local_player = get_local_player()
    if not local_player then return end
    
    local is_helltide = GameStateChecker.is_in_helltide(local_player)
    console.print("Is in Helltide: " .. tostring(is_helltide))
    console.print("Waiting for teleport: " .. tostring(self.state.waiting_for_teleport))
    console.print("Teleport completed: " .. tostring(self.state.teleport_completed))
    
    if not menu.enable_during_helltide:get() then
        return
    end
    
    if not is_helltide then
        return
    end

    console.print("Checking vendor needs during Helltide...")
    
    local next_action = self:get_next_action(false) or self:get_next_action(true)
    if next_action then
        set_screen_message(string.format("Helltide: %s - Teleporting to Town", 
            action_message[next_action] or "Unknown action"))

        console.print("Starting vendor process during Helltide")
     
        console.print("Deactivating main plugin...")
        self:update_active_plugin()  
        self:save_active_plugin()    
        self:set_plugin_state(false)
        
        self.state.waiting_for_teleport = true
        self.state.teleport_completed = false
        
        self.state.current_target = nil
        self.state.current_action = nil
        
        return
    end

    if self.state.waiting_for_teleport then
        set_screen_message("Waiting for town teleport...")
        if not self.state.teleport_completed then
            local teleport_state = vendor_teleport.get_state()
            local teleport_info = vendor_teleport.get_info()
            console.print(string.format("Teleport status: %s (Attempts: %d/%d)", 
                teleport_state, teleport_info.attempts, teleport_info.max_attempts))
            
            local teleport_result = vendor_teleport.teleport_to_tree()
            
            if vendor_teleport.get_state() == "cooldown" then
                console.print("Teleport on cooldown, resetting states...")
                self.state.waiting_for_teleport = false
                self.state.teleport_completed = false
                vendor_teleport.reset()
                self:restore_original_plugin()
            end
        end
        return
    end
end

function InventoryManager:can_perform_action()
    local current_time = os.clock()
    if current_time - self.state.last_action_time >= self.CONSTANTS.ACTION_DELAY then
        self.state.last_action_time = current_time
        return true
    end
    return false
end

function InventoryManager:get_next_action(ignore_threshold)
    local local_player = get_local_player()
    if not local_player then return nil end

    local function check_inventory_items(ignore_threshold)
        local items = local_player:get_inventory_items()
        if not items then return false end
        
        if ignore_threshold then
            return #items > 0
        else
            return #items >= menu.items_threshold:get()
        end
    end

    local actions = {
        {
            name = "stash_boss_materials",
            enabled = menu.auto_stash_boss_materials:get(),
            check = function() 
                local consumable_items = local_player:get_consumable_items()
                if not consumable_items then return false end
                
                for _, item in pairs(consumable_items) do
                    if BossMaterialsService:should_stash_material(item) then
                        return true
                    end
                end
                return false
            end
        },
        {
            name = "stash",
            enabled = menu.auto_stash:get(),
            check = function() 
                if ignore_threshold then
                    return StashService:should_stash_item(local_player:get_inventory_items())
                else
                    return check_inventory_items(false) and 
                           StashService:should_stash_item(local_player:get_inventory_items())
                end
            end
        },
        {
            name = "salvage",
            enabled = menu.auto_salvage:get(),
            check = function() 
                if ignore_threshold then
                    return SalvageService:has_items_to_salvage(true)
                else
                    return check_inventory_items(false) and 
                           SalvageService:has_items_to_salvage()
                end
            end
        },
        {
            name = "repair",
            enabled = menu.auto_repair:get(),
            check = function() 
                return RepairService:has_items_to_repair() 
            end
        },
        {
            name = "sell",
            enabled = menu.auto_sell:get(),
            check = function() 
                if ignore_threshold then
                    return SellService:has_items_to_sell(true)
                else
                    return check_inventory_items(false) and 
                           SellService:has_items_to_sell()
                end
            end
        }
    }
    
    for _, action in ipairs(actions) do
        if action.enabled and action.check() then
            console.print("Next action (with threshold):", action.name)
            return action.name
        end
    end

    if ignore_threshold then
        for _, action in ipairs(actions) do
            if action.enabled and action.check(true) then
                console.print("Next action (ignoring threshold):", action.name)
                return action.name
            end
        end
    end
    
    return nil
end

function InventoryManager:find_vendor_for_action(action)
    if action == "stash" or action == "stash_boss_materials" then
        return enums.positions.stash_position
    elseif action == "salvage" or action == "repair" then  -- Repair usa mesmo vendor que salvage
        return enums.positions.blacksmith_position
    elseif action == "sell" then
        return enums.positions.jeweler_position
    end
    return nil
end

function InventoryManager:process_action(action, vendor)
    if action == "stash_boss_materials" then
        set_screen_message("Processing boss materials...")
        return StashService:process_boss_materials(vendor)
    elseif action == "stash" then
        set_screen_message("Processing normal items...")
        return StashService:process_stash_items(vendor)
    elseif action == "salvage" then
        set_screen_message("Salvaging items...")
        return SalvageService:process_salvage_items(vendor)
    elseif action == "repair" then
        set_screen_message("Repairing items...")
        return RepairService:process_repair_items(vendor)
    elseif action == "sell" then
        set_screen_message("Selling items...")
        return SellService:process_sell_items(vendor)
    end
    return false
end

function InventoryManager:is_in_vendor_city()
    local local_player = get_local_player()
    if not local_player then 
        console.print("No local player found")
        return false 
    end
    
    local zone_name = local_player:get_zone_name()
    if not zone_name then
        console.print("No zone name found")
        return false
    end
    
    return zone_name == "Scos_Cerrigar"
end

function InventoryManager:update()
    local is_helltide = GameStateChecker.is_in_helltide()
    local in_vendor_city = self:is_in_vendor_city()

    if not menu.enable_during_helltide:get() then
        return
    end
    
    if not is_helltide then
        return
    end

    local next_action = self:get_next_action(false) or self:get_next_action(true)
    if next_action then
        set_screen_message(string.format("Helltide: %s - Teleporting to Town", 
            action_message[next_action] or "Unknown action"))

        console.print("Starting vendor process during Helltide")
     
        console.print("Deactivating main plugin...")
        self:update_active_plugin()  
        self:save_active_plugin()    
        self:set_plugin_state(false)
        
        self.state.waiting_for_teleport = true
        self.state.teleport_completed = false
        
        self.state.current_target = nil
        self.state.current_action = nil
        
        return
    end

    if self.state.waiting_for_teleport then
        set_screen_message("Waiting for town teleport...")
        if not self.state.teleport_completed then
            local teleport_state = vendor_teleport.get_state()
            local teleport_info = vendor_teleport.get_info()
            console.print(string.format("Teleport status: %s (Attempts: %d/%d)", 
                teleport_state, teleport_info.attempts, teleport_info.max_attempts))
            
            local teleport_result = vendor_teleport.teleport_to_tree()
            
            if vendor_teleport.get_state() == "cooldown" then
                console.print("Teleport on cooldown, resetting states...")
                self.state.waiting_for_teleport = false
                self.state.teleport_completed = false
                vendor_teleport.reset()
                self:restore_original_plugin()
            end
        end
        return
    end
end

function InventoryManager:get_stats()
    return {
        salvage_stats = SalvageService:get_stats(),
        sell_stats = SellService:get_stats(),
        boss_materials = BossMaterialsService:count_materials(),
        current_action = self.state.current_action,
        is_processing = self.state.is_processing,
        retries = self.state.retries  -- Novo campo
    }
end

return InventoryManager