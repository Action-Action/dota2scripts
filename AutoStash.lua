local AutoStash = {}

AutoStash.optionEnable = Menu.AddOption({ "Utility", "Auto Stash Item" }, "Enable", "Auto stash items when in base")

AutoStash.dontStashList = {
    item_aegis = true,
    item_soul_ring = true,
    item_rapier = true,
    item_tpscroll = true,
    item_travel_boots = true,
    item_travel_boots_2 = true,
    item_blink = true,
    item_bottle = true,
    item_faerie_fire = true,
    item_flask = true, -- healing salve
    item_clarity = true,
    item_tango = true,
    item_tango_single = true,
    item_enchanted_mango = true
}

-- stash items when using soul ring in base
function AutoStash.OnPrepareUnitOrders(orders)
    if not Menu.IsEnabled(AutoStash.optionEnable) then return true end
    if not orders or not orders.ability then return true end

    local myHero = Heroes.GetLocal()
    if not myHero then return true end

    if Entity.IsAbility(orders.ability) 
        and Ability.GetName(orders.ability) == "item_soul_ring"
        and NPC.HasModifier(myHero, "modifier_fountain_aura_buff") then
        
        inventory2stash(myHero)
    end

    return true
end

function AutoStash.OnUpdate()
    if not Menu.IsEnabled(AutoStash.optionEnable) then return end

    local myHero = Heroes.GetLocal()
    if not myHero then return end

    -- move items back to inventory afer using soul ring
    if NPC.HasModifier(myHero, "modifier_fountain_aura_buff") 
        and NPC.HasModifier(myHero, "modifier_item_soul_ring_buff") then

        local mod = NPC.GetModifier(myHero, "modifier_item_soul_ring_buff")
        if GameRules.GetGameTime() - Modifier.GetCreationTime(mod) > 0.1 then
            stash2inventory(myHero)
        end
    end

    -- when healed by shrine
    if NPC.HasModifier(myHero, "modifier_filler_heal") then
        local enemyUnits = NPC.GetHeroesInRadius(myHero, 1000, Enum.TeamType.TEAM_ENEMY)
        local mod = NPC.GetModifier(myHero, "modifier_filler_heal")
        if #enemyUnits <= 0 and GameRules.GetGameTime()-Modifier.GetCreationTime(mod) < 0.1 then
            tmpMoveItem2Backpack(myHero)
        end
    end

end

function tmpMoveItem2Backpack(myHero)
    local tmp_slot = 8
    for i = 0, 5 do
        local item = NPC.GetItemByIndex(myHero, i)
        if item then
            local itemName = Ability.GetName(item)
            if not AutoStash.dontStashList[itemName] then
                moveItemToSlot(myHero, item, tmp_slot)
                moveItemToSlot(myHero, item, i)
            end
        end 
    end
end

function inventory2stash(myHero)
    local delta = 9
    for i = 0, 5 do
        local item = NPC.GetItemByIndex(myHero, i)
        if item and not NPC.GetItemByIndex(myHero, i+delta) then
            local itemName = Ability.GetName(item)
            if not AutoStash.dontStashList[itemName] then
                moveItemToSlot(myHero, item, i+delta)
            end
        end
    end
    hasStashed = true
end

function stash2inventory(myHero)
    local delta = 9
    for i = 9, 14 do
        local item = NPC.GetItemByIndex(myHero, i)
        if item and not NPC.GetItemByIndex(myHero, i-delta) then
            moveItemToSlot(myHero, item, i-delta)
        end
    end
    hasStashed = false
end

function moveItemToSlot(myHero, item, slot_index)
    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_ITEM, slot_index, Vector(0, 0, 0), item, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)
end

return AutoStash