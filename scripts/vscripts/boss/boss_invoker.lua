RegistBoss(
{
  name = 'npc_warden_boss_invoker',
  crazytime = 600,
  boss_think = 'BossInvokerThink',
  phases = {
  	[1] = {
  		phase_change_type = 'time_based',
  		phase_duration = 120
  	},
  	[2] = {
  		phase_change_type = 'health_percentage_based',
  		health_threshold = 80
  	},
  	[3] = {
  		phase_change_type = 'health_number_based',
  		health_threshold = 20000
  	}
  	
  }
})
BOSS_INVOKER_ABILITY_MAP = {
  -- phase 1 abilities
  [1] = {
    },
  -- phase 2 abilities
  [2] = {
    },
  -- phase 3 abilities
  [3] = {
    }

}
if InvokerThink == nil then
  InvokerThink = {}
end

function InvokerThink:new(o)
  o = o or self
  setmetable( o , self )
  return o
end

function BossInvokerThink()
  local now = GameRules:GetGameTime()
  if invoker_think_t0 == nil then
    invoker_think_dy = now
  end
  local dt = invoker_think_t0 - now
  
  local thinkEntity = WardenGameMode:GetThinkEntity()
  if not thinkEntity then
    tPrint( ' ERROR: think entity not found' )
    return
  end
  local thinkPhase = WardenGameMode:GetPhase()
  local thinkCrazy = WardenGameMode:GetCrazy()
  InvokerThink:ThinkState(thinkEntity,thinkPhase,thinkCrazy)
end

function InvokerThink:ThinkState(boss,phase,crazy)
  if phase > #WardenGameMode.CurrentBossData.phases then return end
  if crazy then
    -- DO SOME CRAZY THING
  end
  local ability = self:GetCVastableAbility(boss,phase)
  if ability then
    local target = self:GetAbilityTarget(boss,ability)
    boss:CastAbilityOnTarget(ability,target)
  end
end

function InvokerThink:GetAbiltiyTarget(boss,ability)
  local allPlayers = WardenGameMode.vPlayerData
  for _,v in pairs(allPlayers) do
    local hero = v.hero
    if hero:IsAlive() then
      -- TODO THINK ABOUT TAUNTS
      return hero
    end
  end
end

function InvokerThink:GetCastableAbiltiy(boss,phase)
  for k,v in pairs(BOSS_INVOKER_ABILITY_MAP[phase]) do
    local ability = boss:FindAbilityByName(v)
    if ability:IsFullyCastable() then
      return ability
    end
  end
  return nil
end
