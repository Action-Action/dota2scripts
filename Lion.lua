local Utility = require("Utility")

local Lion = {}

local optionAutoHex = Menu.AddOption({"Hero Specific", "Lion"}, "Auto Hex", "Auto hex any enemy in range once lion has level 6")
local optionAutoSpike = Menu.AddOption({"Hero Specific", "Lion"}, "Auto Spike", "Auto spike if enemy is (1) in low HP (kill steal); (2) TPing; (3) channelling; or (4) being stunned or hexed with proper timing")
local optionAutoManaDrain = Menu.AddOption({"Hero Specific", "Lion"}, "Auto Mana Drain", "Auto mana drain to break (1) linken (or AM's shell); (2) illusion")

function Lion.OnUpdate()
    if Menu.IsEnabled(optionAutoHex) then
        Lion.AutoHex()
    end

    if Menu.IsEnabled(optionAutoSpike) then
        Lion.AutoSpike()
    end

    if Menu.IsEnabled(optionAutoManaDrain) then
        Lion.AutoManaDrain()
    end
end

function Lion.AutoHex()
    local myHero = Heroes.GetLocal()
    if not myHero or not Lion.IsSuitableToCastSpell(myHero) then return end
    -- if NPC.GetCurrentLevel(myHero) < 6 then return end

    local spell = NPC.GetAbility(myHero, "lion_voodoo")
    if not spell or not Ability.IsCastable(spell, NPC.GetMana(myHero)) then return end
    local range = Ability.GetCastRange(spell)

    for i = 1, Heroes.Count() do
        local enemy = Heroes.Get(i)
        if enemy and not NPC.IsIllusion(enemy) and not Entity.IsSameTeam(myHero, enemy)
        and Utility.CanCastSpellOn(enemy) and NPC.IsEntityInRange(myHero, enemy, range)
        and not Utility.IsDisabled(enemy) and not Utility.IsLinkensProtected(enemy)
        and not Utility.IsLotusProtected(enemy) then

            if NPC.GetCurrentLevel(myHero) < 30 then
                Ability.CastTarget(spell, enemy)
            else
                Ability.CastPosition(spell, Entity.GetAbsOrigin(enemy))
            end
            return
        end
    end
end

function Lion.AutoSpike()
    local myHero = Heroes.GetLocal()
    if not myHero or not Lion.IsSuitableToCastSpell(myHero) then return end

    local spell = NPC.GetAbility(myHero, "lion_impale")
    if not spell or not Ability.IsCastable(spell, NPC.GetMana(myHero)) then return end
    local range = Ability.GetCastRange(spell)
    local damage = 20 + 60 * Ability.GetLevel(spell)
    local speed = 1600

    for i = 1, Heroes.Count() do
        local enemy = Heroes.Get(i)
        if enemy and not NPC.IsIllusion(enemy) and not Entity.IsSameTeam(myHero, enemy)
        and Utility.CanCastSpellOn(enemy) and NPC.IsEntityInRange(myHero, enemy, range) then

            -- spike the enemy who is channelling a spell or TPing
            if Utility.IsChannellingAbility(enemy) then
                Ability.CastPosition(spell, Entity.GetAbsOrigin(enemy))
                return
            end

            -- spike the enemy who is being stunned or hexed with proper timing
            local dis = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length()
            local delay = 0.3 + dis/speed

            if (Utility.GetHexTimeLeft(enemy) - 0.1 < delay and delay < Utility.GetHexTimeLeft(enemy) + 0.1)
            or (Utility.GetStunTimeLeft(enemy) - 0.1 < delay and delay < Utility.GetStunTimeLeft(enemy) + 0.1) then
                Ability.CastPosition(spell, Utility.GetPredictedPosition(enemy, delay))
                return
            end

            -- spike the enemy who is in low HP (for kill steal)
            local true_damage = damage * NPC.GetMagicalArmorDamageMultiplier(enemy)
            if true_damage >= Entity.GetHealth(enemy) then
                Ability.CastPosition(spell, Utility.GetPredictedPosition(enemy, delay))
                return
            end
        end
    end
end

function Lion.AutoManaDrain()
    local myHero = Heroes.GetLocal()
    if not myHero or not Lion.IsSuitableToCastSpell(myHero) then return end

    local spell = NPC.GetAbility(myHero, "lion_mana_drain")
    if not spell or not Ability.IsCastable(spell, NPC.GetMana(myHero)) then return end
    local range = Ability.GetCastRange(spell)

    for i = 1, Heroes.Count() do
        local enemy = Heroes.Get(i)
        if enemy and not Entity.IsSameTeam(myHero, enemy)
        and Utility.CanCastSpellOn(enemy) and NPC.IsEntityInRange(myHero, enemy, range) then

            if Utility.IsLinkensProtected(enemy) or NPC.IsIllusion(enemy) then
                Ability.CastTarget(spell, enemy)
                return
            end
        end
    end
end

function Lion.IsSuitableToCastSpell(myHero)
    if NPC.IsSilenced(myHero) or NPC.IsStunned(myHero) or not Entity.IsAlive(myHero) then return false end
    if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return false end
    if NPC.HasModifier(myHero, "modifier_teleporting") then return false end
    -- disable this check for mana_drain
    -- if NPC.IsChannellingAbility(myHero) then return false end

    return true
end

return Lion
