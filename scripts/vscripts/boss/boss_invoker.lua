RegistBoss({
  name = 'npc_warden_boss_invoker',
  crazytime = 600,
  boss_think = 'BossInvokerThink',
  phases = {
    [1] = {
  		name = 'npc_warden_boss_invoker',
  		crazytime = 600,
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
  	}
  }
})

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
    tPrint()
  end
  local thinkPhase = WardenGameMmode()
  
end
