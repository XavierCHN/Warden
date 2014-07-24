tPrint(' executing abilityhook.lua')


------------------------------------------------------------------------------------------------------------------
local SUB_ABILITIES = {
}
local DUMMY_ABILITIES = {
}
------------------------------------------------------------------------------------------------------------------
if AbilityHook == nil then
  AbilityHook = {}
end
------------------------------------------------------------------------------------------------------------------
function AbilityHook:new( o )
  o = o or {}
  setmetable( o, self )
  return o
end
------------------------------------------------------------------------------------------------------------------
function AbiltiyHook:Init()
  self.all_abilties = ALL_ABILITY_MAP
  for k,v in pairs( SUB_ABILITIES ) do
    self.sub_abilities[k] = v
  end
  for k,v in pairs( DUMMY_ABILITIES ) do
   self.dummy_abilities[k] = v
  end
end
------------------------------------------------------------------------------------------------------------------
local function AbilityHook:GetSubAbility( ability )
  if self.sub_abilities[ability] then
   return self.sub_abilities[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
local function AbilityHook:GetDummyAbility( ability )
  if self.dummy_abilities[ability] then
    return self.dummy_abilities[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
local function AbilityHook:IsStoredAbility( caster, ability )
  if ability == ElementThinker:StoredAbility[caster] then return true end
  return false
end
------------------------------------------------------------------------------------------------------------------
-- get the sub ability for the casted ability and add sub ability
local function AddSubAbility(keys, ability )
  tPrint( 'add sub ability called' )
  local sub_ability = AbilityHook:GetSubAbility( ability )
  if sub_ability then
    tPrint( 'add sub ability '..sub_ability )
    if AbilityHook:IsStoredAbility( caster, ability ) then caster:RemoveAbility('ability_warden_empty') end
    if not AbilityHook:IsStoredAbility( caster, ability ) then
      caster:RemoveAbility('ability_warden_store_empty')
      ElementThinker:ChangeStoredAbility( sub_ability )
    end
    caster:AddAbility(sub_ability)
    caster:FindAbilityByName( sub_ability ):SetLevel(1)
  end
end
------------------------------------------------------------------------------------------------------------------
-- if an ability has an dummy ability , fire it
local function FireDummyAbility(keys, ability )
  if AbilityHook:GetDummyAbility( ability ) then
    local dummy_ability = AbilityHook:GetDummyAbility( ability )
    caster:AddAbility( dummy_ability )
    caster:FindAbilityByName( dummy_ability ):SetLevel( 1 )
    local tAbility = caster:FindAbilityByName( dummy_ability )
    local ability_cast_type = tAbility:GetSpecialValueFor( 'cast_type' )

    if ability_cast_type == 'no_target' then
      caster:CastAbilityNoTarget( dummy_ability, 0 )
    end
    if ability_cast_type == 'unit_target' then
      local target = keys.target
      caster:CastAbilityOnTarget( target, dummy_ability, 0 )
    end
    if ability_cast_type == 'position_target' then
      local target = keys.target_points[1]
      caster:CastAbilityOnPosition(target, dummy_ability, 0 )
  end
end
------------------------------------------------------------------------------------------------------------------
-- called from npc_abilities_custom.txt
function OnAbilityCasted( keys )

  PrintTable( keys )
  local caster = EntIndexToHScript( keys.caster_index )
  local abiltiy = keys.ability
  tPrint( 'trying to catch sub ability and dummy ability for '..ability )
  
  GetSubAbility(keys, ability )
  FireDummyAbility(keys, ability )
end
