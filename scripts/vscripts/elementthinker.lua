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
	self.NormalAbility = {}
	self.StoredAbility = {}
    self.EnableAbility = {}
end
------------------------------------------------------------------------------------------------------------------
function ElementThinker:GetSubAbility( ability )
  if SUB_ABILITIES[ability] then
   return SUB_ABILITIES[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
function ElementThinker:GetDummyAbility( ability )
  if DUMMY_ABILITIES[ability] then
    return DUMMY_ABILITIES[ability]
  end
  return nil
end
------------------------------------------------------------------------------------------------------------------
function ElementThinker:RebuildAllAbilities( hero , changeFlag , toChangeAbility )
    local ability_map = {
        [1] = 'ability_warden_q',
        [2] = 'ability_warden_w',
        [3] = 'ability_warden_e',
        [4] = self.NormalAbility[hero] or 'ability_warden_normal_empty',
        [5] = self.StoredAbility[hero] or 'ability_warden_store_empty',
        [6] = self.EnableAbility[hero] or 'ability_warden_enable_empty'
    }
    for _,ability in pairs( ability_map ) do
        hero:RemoveAbility(ability)
    end
    if changeFlag == 'CHANGE_NORMAL' then
        ability_map[4] = toChangeAbility
    end
    if changeFlag == 'CHANGE_STORE' then
        ability_map[5] = toChangeAbility
    end
    if changeFlag == 'CHANGE_ENABLE' then
        ability_map[6] = toChangeAbility
    end
    for _,ability in pairs( ability_map ) do
        hero:AddAbility(ability)
    end
    for _,ability in pairs( ability_map ) do 
        local ab = hero:FindAbilityByName(ability)
        if ab then ab:SetLevel(1) end
    end
    self.NormalAbility[hero] = ability_map[4]
    self.StoredAbility[hero] = ability_map[5]
    self.EnableAbility[hero] = ability_map[6]
end
------------------------------------------------------------------------------------------------------------------
-- if an ability has an dummy ability , fire it
function ElementThinker:FireDummyAbility(keys, ability )
  if ElementThinker:GetDummyAbility( ability ) then
    -- TODO
  end
end
------------------------------------------------------------------------------------------------------
-- return ability according to modifiers
-- the result ability is 'ability_warden_qqqqq'
-- or 'ability_warden_qwqwq'
function ElementThinker:GetResultAbility(hero , plyid)
	-- if the player has no any elements, return empty ability
	if self.Elements[hero] == nil then
		return 'ability_warden_normal_empty'
	end
	-- catch the result ability
	local resultAbility = 'ability_warden_result_'
	for i = 1,#self.Elements[hero] do
		resultAbility = resultAbility..string.sub(self.Elements[hero][i],-1,-1)
	end
    tPrint(' attempt to get result ability of:'..resultAbility)
	for _,v in pairs(ALL_ABILITIES) do
		if resultAbility == v then
			tPrint(' avilable ability found'..resultAbility)
			return resultAbility
		end
	end
	return 'ability_warden_normal_empty'
end
------------------------------------------------------------------------------------------------------
-- clear all modifiers from hero
function ElementThinker:ClearAllModifiers(hero , plyid)
    if not self.Elements[hero] then return end
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
    self.Elements[hero] = self.Elements[hero] or {}
	table.insert(self.Elements[hero],newElement)
	if #self.Elements[hero] > 5 then
		self:RemoveFirstModifier(hero , plyid)
	end
	
	local resultAbility = self:GetResultAbility(hero , plyid)
	-- unable to have same ability
	if resultAbility == self.StoredAbility[hero] then
		resultAbility = 'ability_warden_normal_empty'
	end
	
    if resultAbility then
        self:RebuildAllAbilities( hero, 'CHANGE_NORMAL', resultAbility)
    end

    if resultAbility ~= 'ability_warden_normal_empty' then
        self:RebuildAllAbilities( hero, 'CHANGE_ENABLE', 'ability_warden_enable')
    else
        self:RebuildAllAbilities( hero, 'CHANGE_ENABLE', 'ability_warden_enable_empty')
    end
end
------------------------------------------------------------------------------------------------------
function ElementThinker:StoreAbility(hero,plyid)
    self:ClearAllModifiers(hero,plyid)

    self:RebuildAllAbilities( hero, 'CHANGE_STORE', self.NormalAbility[hero])
    self:RebuildAllAbilities( hero, 'CHANGE_NORMAL','ability_warden_normal_empty')

    if self.NormalAbility[hero] ~= 'ability_warden_normal_empty' then
        self:RebuildAllAbilities( hero, 'CHANGE_ENABLE', 'ability_warden_enable')
    else
        self:RebuildAllAbilities( hero, 'CHANGE_ENABLE', 'ability_warden_enable_empty')
    end
end
------------------------------------------------------------------------------------------------------
function ElementThinker:StoredAbilityCasted(hero , plyid , ability)
    self:ClearAllModifiers(hero,plyid)
	if self:GetSubAbility(ability) then
        self:RebuildAllAbilities( hero, 'CHANGE_STORE', self:GetSubAbility(ability))
    else
        self:RebuildAllAbilities( hero, 'CHANGE_STORE', 'ability_warden_store_empty')
    end
end
------------------------------------------------------------------------------------------------------
function ElementThinker:NormalAbilityCasted(hero , plyid , ability)
	self:ClearAllModifiers(hero,plyid)
	
    if self:GetSubAbility(ability) then
        self:RebuildAllAbilities( hero, 'CHANGE_NORMAL', self:GetSubAbility(ability))
    else
        self:RebuildAllAbilities( hero, 'CHANGE_NORMAL', 'ability_warden_normal_empty')
    end
end
------------------------------------------------------------------------------------------------------
function OnElement(keys)
    PrintTable( keys )

  	local caster = EntIndexToHScript(keys.caster_entindex)
  	local plyid = caster:GetPlayerID()
  	local newElement = keys.Element

     tPrint(' On Element '..newElement )
  	ElementThinker:RefreshAbility(caster,plyid,newElement)
end
------------------------------------------------------------------------------------------------------
function ElementThinker:OnAbilityCast(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local plyid = caster:GetPlayerID()
	local abilityCasted = keys.Ability

	if abilityCasted == ElementThinker.StoredAbility[caster] then
		tPrint(' [ElementThinker] ability casted, stored ability'..abilityCasted)
		ElementThinker:StoredAbilityCasted(caster,plyid,abilityCasted)
	elseif abilityCasted == ElementThinker.NormalAbility[caster] then
		tPrint(' [ElementThinker] ability casted, normal ability'..abilityCasted)
		ElementThinker:NormalAbilityCasted(caster,plyid,abilityCasted)
	else
		tPrint(' [ElementThinker] ability casted, other ability'..abilityCasted)
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

