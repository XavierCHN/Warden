WARDEN_ADDON_VERSION = 'APLHA 0.1'

tPrint('gamemode version:'..WARDEN_ADDON_VERSION)
tPrint('executing warden.lua')

USE_LOBBY = false
-----------------------------------------------------------------------------------
--GOLD CONSTANT--
-----------------------------------------------------------------------------------
GOLD_INIT = 700
GOLD_PER_WINNER = 1000
GOLD_PER_LOSER = 600
GOLD_PER_KILL = 200
GOLD_PER_TICK = 2
GOLD_WINNER_RELIABLE = false
-----------------------------------------------------------------------------------
--GAME TIME CONSTANT
-----------------------------------------------------------------------------------
GAMETIME_PREGAME = 10
GAMETIME_POSTGAME = 50
GAMETIME_PRATICEGAME = 60
GAMETIME_AFTER_PRATICE = 10
GAMETIME_PRE_ROUND = 30
-----------------------------------------------------------------------------------
--ROUND CONSTANT
-----------------------------------------------------------------------------------
ROUNDS_TOTAL = 11
ROUND_NUMBER = 0
ROUNDS_WIN_RADIANT = 0
ROUNDS_WIN_DIRE    = 0
-----------------------------------------------------------------------------------
--TEAM VARIABLE
-----------------------------------------------------------------------------------
TEAM_SIZE_RADIANT = 0
TEAM_SIZE_DIRE    = 0
TEAM_SCORE_RADIANT = 0
TEAM_SCORE_DIRE    = 0
-----------------------------------------------------------------------------------
INIT_ABILITY_MAP = {
	'ability_warden_q',
	'ability_warden_w',
	'ability_warden_e',
	'ability_warden_normal_empty',
	'ability_warden_store_empty',
	'ability_warden_store'
}
-----------------------------------------------------------------------------------
ALL_ABILITY_MAP = {
	'ability_warden_q',
	'ability_warden_w',
	'ability_warden_e',
	'ability_warden_normal_empty',
	'ability_warden_store_empty',
	'ability_warden_store'
}
-----------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
-- create game mode var
if WardenGameMode == nil then
	WardenGameMode = {}
	WardenGameMode.szEntityClassName = "warden"
	WardenGameMode.szEntityClassName = "dota_base_game_mode"
	WardenGameMode.__index = WardenGameMode
end
-----------------------------------------------------------------------------------
-- game mode new
function WardenGameMode:new(o)
	o = o or {}
	setmetatable(o, self)
	return o
end
-----------------------------------------------------------------------------------
-- init game mode    --called in addon_game_mode.lua
function WardenGameMode:Init()

	-- Setup GameRules
	GameRules:SetTreeRegrowTime( 30.0 )
	GameRules:SetHeroSelectionTime( 0.0 )
	GameRules:SetPreGameTime( GAMETIME_PREGAME )
	GameRules:SetPostGameTime( GAMETIME_POSTGAME )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetTimeOfDay( 0.25 )
	-- TODO CHANGE THIS TO A PROPER VALUE
	GameRules:SetHeroMinimapIconSize( 300 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetSafeToLeave( false )
	GameRules:SetUseCustomHeroXPValues( false )
	GameRules:SetGoldTickTime( 1 )
	GameRules:SetGoldPerTick( GOLD_PER_TICK )

	-- Setup GameMode, and Initial Top Bar Values
	GameMode = Entities:FindAllByClassname('dota_base_game_mode')[1]
	GameMode:SetTopBarTeamValuesOverride( true )
	GameMode:SetTopBarTeamValue( DOTA_TEAM_GOODGUYS, 0 )
	GameMode:SetTopBarTeamValue( DOTA_TEAM_BADGUYS , 0 )

	--setup thinkState for later switching of thinkstates
	self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_PreGame' )

	-- Setup game Hooks
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(WardenGameMode, 'OnItemPickUp'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(WardenGameMode, 'OnItemPurchased'), self)
	ListenToGameEvent('onItemDropped', Dynamic_Wrap(WardenGameMode, 'OnItemDropDown'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(WardenGameMode, 'OnPlayerConnectFull'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(WardenGameMode, 'OnPlayerConnect'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(WardenGameMode, 'OnPlayerDisconnect'), self)
	ListenToGameEvent('player_say', Dynamic_Wrap(WardenGameMode, 'OnPlayerSay'), self)

	self:RegisterCommands()

	GameMode:SetContextThink("FreezetagThink", Dynamic_Wrap( WardenGameMode, 'Think' ), 0.25 )

	self.vPlayerData = {}
	self.vPlayerNames = {}

	self.bStatePlaying = false

	tPrint('done init warden game mode \n\n')

end
-----------------------------------------------------------------------------------
-- regist console commands
function WardenGameMode:RegisterCommands()
	ConVars:RegisterConvar('WARDEN_FAKE_CLIENTS',function()
			for index=0, 9 do
				if PlayerResource:IsFakeClient(index) then
					local ply = PlayerResource:GetPlayer(index)
					if ply then
						self:OnAssignBots({ index = ply:entindex() - 1})
					end
				end
			end
		end,
		'fill the server with fake clients',FCVAR_CHEAT)
	Convars:RegisterCommand('WARDEN_CHANGE_TIME', function( name, time )
		if time then
			GameRules:SetTimeOfDay( tonumber(time) )
			self.daytime = tonumber(time)
		else
			tPrint(' ERROR: CHANGE TIME INVALID ARGS')
		end
	end, 'Force a time change', FCVAR_CHEAT)
	Convars::RegisterCommand('WARDEN_END_ROUND', function( name, winner )
		if winner then
			if winner == '2' then
				winner = 2
			elseif winner == '3' then
				winner = 3
			end

			tPrint(' DEBUG: FORCE END ROUND')
			self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_PostRound' )

			self:DistributeScore(winner)
			self:DistributeGold(winner)

			GAME_WINNER = self:CheckGameScore()
			if GAME_WINNER then

				print(' DEBUG: ENTER POST GAME')
				self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_PostGame' )
				return
			end

			ROUND_WINNER = nil
		else
			print(' ERROR: END ROUND INVALID ARGS')
		end
	end, 'Forcefully End The Round', FCVAR_CHEAT)
end
-----------------------------------------------------------------------------------
-- Overall Think function. Is called every 0.25 seconds.
function WardenGameMode:Think()

	-- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
	local now = GameRules:GetGameTime()
	if WardenGameMode.t0 == nil then
		WardenGameMode.t0 = now
	end
	local dt = now - WardenGameMode.t0
	WardenGameMode.t0 = now
	-- Run Current ThinkState
	WardenGameMode:thinkState( dt )
	return 0.25
end
-----------------------------------------------------------------------------------
-- pregame time think
function WardenGameMode:_thinkState_PreGame( dt )
	if GameRules:State_Get() <= DOTA_GAMERULES_STATE_PRE_GAME then
		return
	end
	tPrint(' GAME THINK ENDS PRE GAME')
	GameRules:SendCustomMessage('<font color="#3498db">WARDEN GAME MODE</font>', 0, 0)
	GameRules:SendCustomMessage('<font color="#ecf0f1">Created by: XavierCHN</font>', 0, 0)
	GameRules:SendCustomMessage('<font color="#ecf0f1">github.com/XavierCHN/Warden</font>', 0, 0)
	GameRules:SendCustomMessage("<font color="#3498db">Pratice in next "..GAMETIME_PRATICEGAME.." seconds</font>", 0, 0)

	self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_Pratice' )
end
-----------------------------------------------------------------------------------
-- time for player to pratice game mode
function WardenGameMode:_thinkState_Pratice( dt )

	-- The Timer that counts down the until the warmup is over.
	if self.WarmupTimeLeft == nil then
		self.WarmupTimeLeft = GAMETIME_PRATICEGAME
	end
	self.WarmupTimeLeft = math.max (0, self.WarmupTimeLeft - dt)

	-- Check if there is still warmup time left, and if not move to next stage of game.
	if self.WarmupTimeLeft > 0 then
	else
		
		-- TODO Move onto next stage of game.
		tPrint(' GAME THINK ENTERING PREGAME')

		-- enter state playing 
		self.bStatePlaying = true

		-- change the think state
		self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_PreRound' )
		self.WarmupTimeLeft = nil
	end
end
-----------------------------------------------------------------------------------
-- time between rounds
function WardenGameMode:_thinkState_PreRound( dt )

	if self.PreTimeLeft == nil then
		self.PreTimeLeft = GAMETIME_PRE_ROUND

		-- Reset the time to day, as well as stored time to day
		GameRules:SetTimeOfDay( 0.25 )
		self.daytime = 0.25

		-- Respawns everyone, thus placing them at the spawn points.apply root and silenced modifier
		self:ResetAllHeroes()

	end
	self.PreTimeLeft = math.max (0, self.PreTimeLeft - dt)
	if self.PreTimeLeft > 0 then
	else

		-- reset all units
		self:ResetAllHeroes()
		-- remove root and silenced modifier
		self:ActiveAllHero()

		-- tell the round number
		ROUND_NUMBER = ROUND_NUMBER + 1
		local s = 'ROUND '..ROUND_NUMBER..' START'
		GameRules:SendCustomMessage( s , 0 , 0 )

		-- change the think state
		self.thinkState = Dynamic_Wrap( WardenGameMode, '_thinkState_InRound' )

		self.PreTimeLeft = nil
	end
end
-----------------------------------------------------------------------------------
function WardenGameMode:_thinkState_InRound( dt )
	
	ROUND_WINNER = self:CheckRoundWinner()

	if ROUND_WINNER ~= nil then
		if ROUND_NUMBER > ROUNDS_TOTAL - 1 then
			self.thinkState = Dynamic_Wrap( FreezetagGameMode, '_thinkState_PostGame' )
		else

			GameRules:SendCustomMessage('ROUND '..ROUND_NUMBER..' WINNER: '..ROUND_WINNER, 0, 0)
			if ROUND_WINNER == 'RADIANT' then
				ROUNDS_WIN_RADIANT = ROUNDS_WIND_RADIANT + 1
			else
				ROUNDS_WIN_DIRE = ROUNDS_WIN_DIRE + 1
			end

			self:UpdateScoreBar(ROUNDS_WIN_RADIANT, ROUNDS_WIN_DIRE)
			self:ModifyTeamGold(ROUND_WINNER)

			self.thinkState = Dynamic_Wrap( FreezetagGameMode, '_thinkState_PreRound' )
		end
		return
	end

end
-----------------------------------------------------------------------------------
function WardenGameMode:_thinkState_PostGame( dt )

	local GAME_WINNER = nil
	if ROUNDS_WIN_RADIANT > ROUNDS_WIN_DIRE then
		GAME_WINNER = DOTA_TEAM_GOODGUYS
	else
		GAME_WINNER = DOTA_TEAM_BADGUYS
	end
	GameRules:SetSafeToLeave( true )
	GameRules:SetGameWinner( GAME_WINNER )

end
-----------------------------------------------------------------------------------
function WardenGameMode:CheckRoundWinner()
	local RADIANT_ALIVE_HERO_COUNT = 0
	local DIRE_ALIVE_HERO_COUNT    = 0
	for i, hero in pairs(HeroList:GetAllHeroes()) do
		local team = hero:GetTeam()
		if hero:IsRealHero() then
			if hero:IsAlive() then
				if team = 2 then 
					RADIANT_ALIVE_HERO_COUNT = RADIANT_ALIVE_HERO_COUNT + 1
				end
				if team = 3 then 
					DIRE_ALIVE_HERO_COUNT = DIRE_ALIVE_HERO_COUNT + 1
				end
			end
		end
	end

	if RADIANT_ALIVE_HERO_COUNT <= 0 then
		return 'RADIANT'
	end
	if DIRE_ALIVE_HERO_COUNT <= 0 then
		return 'DIRE'
	end
	return nil
end
-----------------------------------------------------------------------------------
function WardenGameMode:UpdateScoreBar( scoreRadiant, scoreDire)
	GameMode:SetTopBarTeamValue(2,scoreRadiant)
	GameMode:SetTopBarTeamValue(3,scoreDire)
end
-----------------------------------------------------------------------------------
function WardenGameMode:ResetAllHeroes()
	for i, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:HasModifier('modifier_warden_root_n_silenced') then hero:RemoveModifierByName('modifier_warden_root_n_silenced') end
		hero:RespawnHero(false, false, false)
		if hero:HasAbility('ability_warden_root_n_silenced') then
			hero:CastAbilityNoTarget(hero:FindAbilityByName("ability_warden_root_n_silenced"), 0)
		end
		
		-- reset all abilities
		self:InitHero(hero)
	end
end
-----------------------------------------------------------------------------------
function WardenGameMode:ActiveAllHero()
	for i, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:HasModifier('modifier_warden_root_n_silenced') then 
			hero:RemoveModifierByName('modifier_warden_root_n_silenced') 
		end
	end
end
-----------------------------------------------------------------------------------
function WardenGameMode:ModifyTeamGold(winner)
	for plyid,_ in pairs(self.vPlayerData)
		local player = PlayerResource:GetPlayer(plyid)
		local hero = player:GetAssignedHero()
		local team = player:GetTeam()

		if winner = "RADIANT" then
			if team = 2 then
				hero:ModifyGold( GOLD_PER_WINNER , GOLD_WINNER_UNRELIABLE , 1 )
			end
			if team = 3 then 
				hero:ModifyGold( GOLD_PER_LOSER , true , 1)
			end
		end
		if winner = "DIRE" then
			if team = 2 then
				hero:ModifyGold( GOLD_PER_LOSER , true , 1 )
			end
			if team = 3 then 
				hero:ModifyGold( GOLD_PER_WINNER , GOLD_WINNER_UNRELIABLE , 1)
			end
		end
	end
end
-----------------------------------------------------------------------------------
function WardenGameMode:OnPlayerConnect( keys )
	self.vPlayerNames[keys.index] = keys.name
end
-----------------------------------------------------------------------------------
function WardenGameMode:OnPlayerConnectFull( keys )
	if self.vPlayerData == nil then self.vPlayerData = {} end

	local playerIndex = keys.index + 1
	local ply = EntIndexToHScript(playerIndex)
	local plyid = ply:GetPlayerID()

	if self.vPlayerData[plyid] == nil then
		if not USE_LOBBY and plyid == -1 then 
			if TEAM_SIZE_RADIANT > TEAM_SIZE_DIRE then
				ply:SetTeam(DOTA_TEAM_BADGUYS)
				TEAM_SIZE_DIRE = TEAM_SIZE_DIRE + 1
			else
				ply:SetTeam(DOTA_TEAM_GOODGUYS)
				TEAM_SIZE_RADIANT = TEAM_SIZE_RADIANT + 1
			end
		end

		local assignedHero = CreateHeroForPlayer('npc_dota_hero_dragon_knight', ply)
		self:InitHero(assignedHero)
		self.vPlayerData[plyid] = {
			hero = assignedHero,
			steamid = PlayerResource:GetSteamAccountID(plyid)
		}

	end
end
-----------------------------------------------------------------------------------
function WardenGameMode:InitHero(hero)
	-- level up the hero to 25
	local level = hero:GetLevel()
	while level < 25 do
		hero:HeroLevelUp(false)
		level = hero:GetLevel()
	end

	for _,ability in pairs(ALL_ABILITY_MAP) do
		if hero:HasAbility(ability) then
			tPrint(' remove abiltiy '..ability..' from hero '..hero:GetName())
			hero:RemoveAbility(ability)
		end
	end

	-- add all init ability and set level
	for _,ability in pairs(INIT_ABILITY_MAP) do
		if not hero:HasAbility(ability) then
			hero:AddAbility(ability)
		end
		hero:FindAbilityByName(abiltiy):SetLevel(1)
	end

	-- set ability points
	hero:SetAbilityPoints(0)

end
-----------------------------------------------------------------------------------
function WardenGameMode:OnItemPickUp( keys )
end
-----------------------------------------------------------------------------------
function WardenGameMode:OnItemPurchased( keys )
end
-----------------------------------------------------------------------------------
function WardenGameMode:OnPlayerDisconnect( keys )
end
-----------------------------------------------------------------------------------
function WardenGameMode:OnPlayerSay( keys )
end
-----------------------------------------------------------------------------------
