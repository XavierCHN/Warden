if ThreatSystem == nil then
  ThreatSystem = {}
end

function ThreatSystem:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end

function ThreatSystem:NewThreat( unit , target )
	self.Aggro = self.Aggro or {}
	self.Aggro[target] = self.Aggro[target] or {}
	self.Aggro[target][unit] = self.Aggro[target][unit] or 0
end

function ThreatSystem:AddAggro( unit , target , amount)
	if self.Aggro[target].keep then return end
	self.Aggro[target][unit] = self.Aggro[target][unit] or 0
	self.Aggro[target][unit] = self.Aggro[target][unit] + amount
end

function ThreatSystem:ReduceAggro( unit , target , amount )
	if self.Aggro[target].keep then return end
	self.Aggro[target][unit] = self.Aggro[target][unit] or 0
	self.Aggro[target][unit] = self.Aggro[target][unit] - amount
end

function ThreatSystem:RefreshAggroTable(tbl)
	for k,v in pairs(tbl) do
		if not k:IsValidEntity() then
			v = 0
			break
		end
		if not k:IsAlive() then
			v = 0
			break
		end
	end
end

function ThreatSystem:GetAggro( target )
	-- ensure the unit is alive
	self:RefreshAggroTable(self.Aggro[target])

	-- return the aggro table
	return self.Aggro[target]
end

function ThreatSystem:GetAggroAtSquence( target , squence)
	-- ensure the unit is alive
	self:RefreshAggroTable(self.Aggro[target])

	if not self.Aggro[target] then
		tPrint('ERROR: target aggro not defined')
		return
	end
	local targetAggro = self.Aggro[target]

	local sortFunc = function(a, b) return b < a end
	table.sort( targetAggro , sortFunc )

	local returnAggro = {}
	local od = 1
	for k,_ in pairs(targetAggro) do
		returnAggro[od] = k
		od = od + 1
	end
	return returnAggro[squence]
end

function ThreatSystem:ClearAggro( target )
	self.Aggro[target] = {}
end

function ThreatSystem:KeepAggro( target )
	self.Aggro[target].keep = self.Aggro[target].keep or {}
	self.Aggro[target].keep = true
end

function AddAggro( keys )
	tPrintTable(keys)
	if not keys.AggroUnit then
		tPrint( 'Aggro Unit Not Defined in ability' )
		return
	end
	--TODO , COLLET KEYS
	local target = keys.target_entindex or WardenGameMode.CurrentBossData.unit or 'empty'
	target = EntIndexToHScript(target)
	local unit = keys.caster_entindex or keys.attacker or 'empty'
	unit = EntIndexToHScript(unit)
	local amount = keys.amount or 0

	ThreatSystem:NewThreat( unit , target )
	ThreatSystem:AddAggro( unit, target , amount )
end

function ReduceAggro( keys )
	tPrintTable(keys)
	local target = keys.target_entindex or WardenGameMode.CurrentBossData.unit or 'empty'
	target = EntIndexToHScript(target)
	local unit = keys.caster_entindex or keys.attacker or 'empty'
	unit = EntIndexToHScript(unit)
	local amount = keys.amount or 0

	ThreatSystem:NewThreat( unit , target )
	ThreatSystem:ReduceAggro( unit, target , amount )
end
