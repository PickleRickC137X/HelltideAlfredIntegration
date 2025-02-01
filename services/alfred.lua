local plugin_label = 'helltide_chests'

local status_enum = {
    IDLE = 'idle',
    WAITING = 'waiting for alfred to complete',
    LOOTING = 'looting stuff on floor'
}

local task = {
    name = 'alfred_running',
    status = status_enum['IDLE']
}

local function floor_has_loot()
    return loot_manager.any_item_around(get_player_position(), 30, true, true)
end

local function is_in_cerrigar()
    local current_world = world.get_current_world()
    if not current_world then return false end
    return current_world:get_name():find("Scos_Cerrigar") ~= nil
end

local function reset()
    PLUGIN_alfred_the_butler.pause(plugin_label)
    if floor_has_loot() then
        task.status = status_enum['LOOTING']
    else
        task.status = status_enum['IDLE']
    end
end

function task.shouldExecute()
    if PLUGIN_alfred_the_butler then
        local status = PLUGIN_alfred_the_butler.get_status()
        if status.inventory_full and
            (status.sell_count > 0 or status.salvage_count > 0) or
            -- boss item
            #get_local_player():get_consumable_items() == 33 or
            -- compass
            #get_local_player():get_dungeon_key_items() == 33
        then
            return true
        elseif task.status == status_enum['WAITING'] or
            task.status == status_enum['LOOTING']
        then
            return true
        end
    end
    return false
end

function task.Execute()
    if task.status == status_enum['IDLE'] then
        PLUGIN_alfred_the_butler.resume()
        task.status = status_enum['WAITING']
        if is_in_cerrigar() then
            PLUGIN_alfred_the_butler.trigger_tasks(plugin_label, reset)
        else
            PLUGIN_alfred_the_butler.trigger_tasks_with_teleport(plugin_label, reset)
        end
    elseif task.status == status_enum['LOOTING'] and get_time_since_inject() > (task.loot_start or 0) + 3 then
        task.status = status_enum['IDLE']
    end
end

return task 