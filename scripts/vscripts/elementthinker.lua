tPrint(' EXECUTING: elementthinker.lua')

if ElementThinker == nil then
	ElementThinker = {}
end
------------------------------------------------------------------------------------------------------
ALL_ABILITIES = {
	"ability_warden_result_qq",
	"ability_warden_result_qe",
	"ability_warden_result_qw",
	"ability_warden_result_qeq",
	"ability_warden_result_qwe",
	"ability_warden_result_qwq",
	"ability_warden_result_qweq",
	"ability_warden_result_qeqe",
	"ability_warden_result_qwqw",
	"ability_warden_result_qwqeq",
	"ability_warden_result_qewqe",

	"ability_warden_result_ew",
	"ability_warden_result_eq",
	"ability_warden_result_ee",
	"ability_warden_result_eqw",
	"ability_warden_result_ewe",
	"ability_warden_result_eqe",
	"ability_warden_result_ewew",
	"ability_warden_result_eqwe",
	"ability_warden_result_eqeq",
	"ability_warden_result_eqwew",
	"ability_warden_result_ewewe",

	"ability_warden_result_ww",
	"ability_warden_result_we",
	"ability_warden_result_wq",
	"ability_warden_result_wqe",
	"ability_warden_result_wqw",
	"ability_warden_result_wew",
	"ability_warden_result_wqew",
	"ability_warden_result_wqwq",
	"ability_warden_result_wewe",
	"ability_warden_result_wqwqw",
	"ability_warden_result_wewew"
}

local SUB_ABILITIES = {
}
local DUMMY_ABILITIES = {
}

------------------------------------------------------------------------------------------------------
-- element thinker new
function ElementThinker:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end
------------------------------------------------------------------------------------------------------
-- element thinker init
function ElementThinker:Init()
	self.Elements = {}
	self.CurrentAbility = {}
	self.StoredAbility = {}
end
------------------------------------------------------------------------------------------------------------------
function ElementThinker:GetSubAbility( ability )
  if self.sub_abilities[ability] then
   return self.sub_abilities[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
function ElementThinker:GetDummyAbility( ability )
  if self.dummy_abilities[ability] then
    return self.dummy_abilities[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
-- get the sub ability for the casted ability and add sub ability
function AddSubAbility(keys, ability )
  tPrint( 'add sub ability called' )
  local sub_ability = ElementThinker:GetSubAbility( ability )
  if sub_ability then
    tPrint( 'add sub ability '..sub_ability )
    if ElementThinker:IsStoredAbility( caster, ability ) then caster:RemoveAbility('ability_warden_empty') end
    if not ElementThinker:IsStoredAbility( caster, ability ) then
      caster:RemoveAbility('ability_warden_store_empty')
      ElementThinker:ChangeStoredAbility( sub_ability )
    end
    caster:AddAbility(sub_ability)
    caster:FindAbilityByName( sub_ability ):SetLevel(1)
  end
end
------------------------------------------------------------------------------------------------------------------
-- if an ability has an dummy ability , fire it
function ElementThinker:FireDummyAbility(keys, ability )
  if ElementThinker:GetDummyAbility( ability ) then
    local dummy_ability = ElementThinker:GetDummyAbility( ability )
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
end
------------------------------------------------------------------------------------------------------
-- return ability according to modifiers
-- the result ability is 'ability_warden_qqqqq'
-- or 'ability_warden_qwqwq'
function ElementThinker:GetAbility(hero , plyid)
	-- if the player has no any elements, return empty ability
	if self.Elements[hero] == nil then
		return 'ability_warden_empty'
	end
	-- catch the result ability
	local resultAbility = 'ability_warden_result_'
	for i = 1,#self.Elements[hero] do
		resultAbility = resultAbility + string.sub(self.Elements[hero][i],-1,-1)
	end
	for _,v in pairs(ALL_ABILITIES) do
		if resultAbility == v then
			tPrint(' avilable ability found'..resultAbility)
			return resultAbility
		end
	end
	return 'ability_warden_empty'
end
------------------------------------------------------------------------------------------------------
-- clear all modifiers from hero
function ElementThinker:ClearAllModifiers(hero , plyid)
	for k,v in pairs(self.Elements[hero]) do
		if hero:HasModifier(v) then
			hero:RemoveModifierByName(v)
		else
			tPrint(' ERROR: ATTEMP TO REMOVE UNEXIST MODIFIER')
		end
	end
	self.Elements[hero] = {}
end
------------------------------------------------------------------------------------------------------
-- remove the first element from hero
function ElementThinker:RemoveFirstModifier(hero , plyid)
	hero:RemoveModifierByName(self.Elements[hero][1])
	table.remove(self.Elements[hero],1)
end
------------------------------------------------------------------------------------------------------
function ElementThinker:RefreshAbility(hero , plyid , newelement)
	local newElement = "modifier_warden_"..newelement
	table.insert(self.Elements[hero],newElement)
	if #self.Elements[hero] > 5 then
		self:RemoveFirstModifier(hero , plyid)
	end
	if self.CurrentAbility[hero] == nil then
		self.CurrentAbility[hero] = 'ability_warden_empty'
		hero:AddAbility('ability_warden_empty')
	end
	-- get the result according to the modifiers
	local resultAbility = self:GetAbility(hero , plyid)
	-- unable to have same ability
	if resultAbility == self.StoredAbility[hero] then
		resultAbility = 'ability_warden_empty'
	end
	-- think about ability store
	if resultAbility ~= "ability_warden_empty" then
		hero:RemoveAbility('ability_warden_store_empty')
		hero:AddAbility('ability_warden_store')
		hero:FindAbilityByName('ability_warden_store'):SetLevel(1)
	else
		if hero:HasAbility('ability_warden_store') then
			hero:RemoveAbility('ability_warden_store')
			hero:AddAbility('ability_warden_store_empty')
			hero:FindAbilityByName('ability_warden_store_empty'):SetLevel(1)
		end
	end
	-- add result ability
	hero:RemoveAbility(self.CurrentAbility[hero])
	hero:AddAbility(resultAbility)
	hero:FindAbilityByName(resultAbility):SetLevel(1)
end
------------------------------------------------------------------------------------------------------
function ElementThinker:StoreAbility(hero,plyid)
	hero:RemoveAbility(self.CurrentAbility[hero])
	hero:AddAbility('ability_warden_empty')
	hero:RemoveAbility(self.StoredAbility[hero])
	hero:AddAbility(self.CurrentAbility[hero])
	hero:FindAbilityByName('ability_warden_empty'):SetLevel(1)
	hero:FindAbilityByName(self.CurrentAbility[hero]):SetLevel(1)
	self.StoredAbility[hero] = self.CurrentAbility[hero]
	self.CurrentAbility[hero] = 'ability_warden_empty'
end
------------------------------------------------------------------------------------------------------
function ElementThinker:StoredAbilityCasted(hero , plyid , ability)
	hero:RemoveAbility(ability)
	local subAbility = self:GetSubAbility( ability )
	local nextAbility = 'ability_warden_store_emtpy'
	if subAbility then nextAbility = subAblity end
	hero:AddAbility( nextAbility )
	self.StoredAbility[hero] = subAbility
	hero:FindAbilityByName(nextAbility):SetLevel(1)
end
------------------------------------------------------------------------------------------------------
function ElementThinker:NormalAbilityCasted(hero , plyid , ability)
	self:ClearAllModifiers(hero,plyid)
	hero:RemoveAbility( ability )
	local subAbility = self:GetSubAbility( ability )
	local nextAbility = 'ability_warden_empty'
	if subAbility then nextAbility = subAblity end
	hero:AddAbility( subAbility )
	self.CurrentAbility[hero] = subAbility
	hero:FindAbilityByName(subAbility):SetLevel(1)
end
------------------------------------------------------------------------------------------------------
function OnElement(keys)
  	local caster = EntIndexToHScript(keys.caster_entindex)
  	local plyid = caster:GetPlayerID()
  	local newElement = keys.Element
  	ElementThinker:RefreshAbility(caster,plyid,newElement)
end
------------------------------------------------------------------------------------------------------
function OnAbilityCast(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local plyid = caster:GetPlayerID()
	local abilityCasted = keys.ability

	if abilityCasted == ElementThinker.StoredAbility[caster] then
		ElementThinker:StoredAbilityCasted(hero,plyid,abilityCasted)
	else
		ElementThinker:NormalAbilityCasted(hero,plyid,abilityCasted)
	end
end
------------------------------------------------------------------------------------------------------
function OnAbilityStore(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local plyid = caster:GetPlayerID()
	if ElementThinker.StoredAbility[caster] == nil then
		ElementThinker.StoredAbility[caster] = 'ability_warden_store_empty'
		if not hero:FindAbilityByName('ability_warden_store_empty') then
			hero:AddAbility('ability_warden_store_empty')
		end
	end
	ElementThinker:StoreAbility(caster,plyid)
end

