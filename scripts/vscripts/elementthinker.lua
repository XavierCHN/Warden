tPrint(' EXECUTING: elementthinker.lua')

if ElementThinker = nil then
	ElementThinker = {}
end
------------------------------------------------------------------------------------------------------
ALL_ABILITIES = {

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
function ElementThinker:init()
	self.Elements = {}
	self.CurrentAbility = {}
	self.StoredAbility = {}
end
------------------------------------------------------------------------------------------------------
-- return ability according to modifiers
-- the result ability is 'ability_warden_qqqqq'
-- or 'ability_warden_qwqwq'
local function ElementThinker:GetAbility(hero , plyid)
	-- if the player has no any elements, return empty ability
	if self.Elements[hero] = nil then
		return 'ability_warden_empty'
	end
	-- catch the result ability
	local resultAbility = 'ability_warden_result_'
	for i = 1,#self.Elements[hero] do
		resultAbility = resultAbility + string.sub(self.Elements[hero][i],-1,-1)
	end
	for _,v in pairs(ALL_ABILITIES) do
		if resultAbility = v then
			tPrint(' avilable ability found'..resultAbility)
			return resultAbility
		end
	end
	return 'ability_warden_empty'
end
------------------------------------------------------------------------------------------------------
-- clear all modifiers from hero
local function ElementThinker:ClearAllModifiers(hero , plyid)
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
local function ElementThinker:RemoveFirstModifier(hero , plyid)
	hero:RemoveModifierByName(self.Elements[hero][1])
	table.remove(self.Elements[hero],1)
end
------------------------------------------------------------------------------------------------------
local function ElementThinker:RefreshAbility(hero , plyid , newelement)
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
	if resultAbility = self.StoredAbility[hero] then
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
local function ElementTHinker:StoreAbility(hero,plyid)
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
local function ElementThinker:StoredAbilityCasted(hero , plyid , ability)
	hero:RemoveAbility(ability)
	hero:AddAbility('ability_warden_store_emtpy')
	hero:FindAbilityByName('ability_warden_store_emtpy'):SetLevel(1)
end
------------------------------------------------------------------------------------------------------
local function ElementThinker:NormalAbilityCasted(hero , plyid , ability)
	self:ClearAllModifiers(hero,plyid)
	hero:RemoveAbility(ability)
	hero:AddAbility('ability_warden_empty')
	self.CurrentAbility[hero] = 'ability_warden_empty'
	hero:FindAbilityByName('ability_warden_empty'):SetLevel(1)
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

