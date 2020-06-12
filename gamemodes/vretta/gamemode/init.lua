--[[
	init.lua - Server Component
	-----------------------------------------------------
	The entire server side bit of Fretta starts here.
]]

DEFINE_BASECLASS( "gamemode_base" )

-- You must add these to make sure the client recieves these scripts
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "skin.lua" )
AddCSLuaFile( "cl_splashscreen.lua" )
AddCSLuaFile( "cl_selectscreen.lua" )
AddCSLuaFile( "cl_gmchanger.lua" )
AddCSLuaFile( "cl_help.lua" )
AddCSLuaFile( "player_extension.lua" )
AddCSLuaFile( "vgui/vgui_hudlayout.lua" )
AddCSLuaFile( "vgui/vgui_hudelement.lua" )
AddCSLuaFile( "vgui/vgui_hudbase.lua" )
AddCSLuaFile( "vgui/vgui_hudcommon.lua" )
AddCSLuaFile( "vgui/vgui_gamenotice.lua" )
AddCSLuaFile( "vgui/vgui_scoreboard.lua" )
AddCSLuaFile( "vgui/vgui_scoreboard_team.lua" )
AddCSLuaFile( "vgui/vgui_scoreboard_small.lua" )
AddCSLuaFile( "vgui/vgui_vote.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_deathnotice.lua" )
AddCSLuaFile( "cl_scores.lua" )
AddCSLuaFile( "cl_notify.lua" )

include( "shared.lua" )
include( "player.lua" )
include( "sv_gmchanger.lua" )
include( "sv_spectator.lua" )
include( "round_controller.lua" )
include( "game_controller.lua" )
include( "utility.lua" )

GM.ReconnectedPlayers = {}

function GM:Initialize()
	
	util.AddNetworkString("PlayableGamemodes")
	util.AddNetworkString("RoundAddedTime")
	util.AddNetworkString("PlayableGamemodes")
	util.AddNetworkString("fretta_teamchange")
	
	-- We need a default single game controller so that we can also have a delay and what not
	
	-- If we're round based, wait 3 seconds before the first round starts
	if ( GAMEMODE.RoundBased ) then
		timer.Simple( 3, function() GAMEMODE:StartRoundBasedGame() end )
	end
	
	if ( GAMEMODE.AutomaticTeamBalance ) then
		timer.Create( "CheckTeamBalance", 30, 0, function() GAMEMODE:CheckTeamBalance() end )
	end
end

hook.Add("Think", "VrettaEndOfGame", function()
	-- Check if the round or game is over from the time
	if( !GAMEMODE.IsEndOfGame && ( !GAMEMODE.RoundBased || ( GAMEMODE.RoundBased && GAMEMODE:CanEndRoundBasedGame() ) ) && CurTime() >= GAMEMODE.GetTimeLimit() ) then
		GAMEMODE:EndOfGame( true )
	end
end)

--[[---------------------------------------------------------
   Name: gamemode:PlayerInitialSpawn( Player ply )
   Desc: Our very first spawn in the game.
---------------------------------------------------------]]
function GM:PlayerInitialSpawn( pl, transition )
	pl:SetTeam( TEAM_UNASSIGNED )
	pl:SetNWBool( "FirstSpawn", true )
	
	-- Players will always spawn when joining the game
	-- Kinda weird behaviour but in GM:PlayerSpawn we can account for this
	-- and kill them before playing a player class that isn't meant for spectating
	
	GAMEMODE:CheckPlayerReconnected( pl )
end

function GM:CheckPlayerReconnected( pl )
	if table.HasValue( GAMEMODE.ReconnectedPlayers, pl:UniqueID() ) then
		GAMEMODE:PlayerReconnected( pl )
	end
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerReconnected( Player ply )
   Desc: Called if the player has appeared to have reconnected.
---------------------------------------------------------]]
function GM:PlayerReconnected( pl )
	-- Use this hook to do stuff when a player rejoins and has been in the server previously
	-- I guess for VIP things?
end

function GM:PlayerDisconnected( pl )
	table.insert( GAMEMODE.ReconnectedPlayers, pl:UniqueID() )
	
	BaseClass.PlayerDisconnected(self, pl)
end  

function GM:ShowHelp( pl )

	pl:SendLua( "GAMEMODE:ShowHelp()" )
	
end

function GM:PlayerSpawn( pl, transition )
	if ( transition ) then return end
	
	local plTeam = pl:Team()
	
	if ( pl:GetNWBool( "FirstSpawn", true ) ) then
		pl:SetNWBool( "FirstSpawn", false )
		
		pl:KillSilent()
		
		pl:SetTeam( TEAM_SPECTATOR )
		
		pl:Spectate( OBS_MODE_ROAMING )
		
		-- Allow fist spawn to change team as soon as possible
		pl.LastTeamChange = 0
		pl.LastTeamSwitch = 0
		pl:SetNWFloat( "RespawnTime", 0 )
		
		return
	end
	
	-- Welp I don't know why I never had this here but this fixed alot of jank
	if (plTeam == TEAM_CONNECTING || plTeam == TEAM_SPECTATOR || (GAMEMODE.TeamBased && plTeam == TEAM_UNASSIGNED)) then return end
	
	local Classes = team.GetClass( plTeam ) -- Returns nil if no classes
	local SpawnClass = pl:GetNWString( "SpawnClass", "" )
	
	-- Player requested a new class, so we set that here
	-- Elsewhere the class gets changed with PlayerJoinTeam
	
	-- Make this also check if the playerclass ever changed
	
	if ( Classes != nil and SpawnClass != "" ) then
		
		player_manager.SetPlayerClass( pl, SpawnClass )
		
		pl:SetNWString( "SpawnClass", "" )
	end
	
	-- Stop observer mode
	pl:UnSpectate()
	
	-- Get the player class just in case nothing was changed on last spawn!
	local pClass = player_manager.GetPlayerClass( pl )
	
	if (pClass == nil) then
		ErrorNoHalt("(VRETTA) Invalid player class!")
		return
	end
	
	local gClass = baseclass.Get( pClass ) -- Will causes errors
	
	if ( gClass.DrawTeamRing ) then pl:SetNWBool( "DrawRing", true ) else pl:SetNWBool( "DrawRing", false ) end
	
	player_manager.OnPlayerSpawn( pl )
	player_manager.RunClass( pl, "Spawn" )
	
	hook.Call( "PlayerSetModel", GAMEMODE, pl )
	
	pl:SetupHands()
	
	if ( not transition ) then
		hook.Call( "PlayerLoadout", GAMEMODE, pl )
	end
end


function GM:AutoTeam( pl )
	
	if ( !GAMEMODE.AllowAutoTeam ) then return end
	if ( !GAMEMODE.TeamBased ) then return end
	
	GAMEMODE:PlayerRequestTeam( pl, team.BestAutoJoinTeam() )
end

concommand.Add( "autoteam", function( pl, cmd, args ) hook.Call( "AutoTeam", GAMEMODE, pl ) end )

function GM:PlayerRequestClass( ply, class, disablemessage )
	-- IMPORTANT: the class is actually a index for the classes table!
	
	local Classes = team.GetClass( ply:Team() )
	if ( Classes == nil ) then return end
	
	local RequestedClass = Classes[ class ]
	if ( RequestedClass == nil ) then return end
	
	if ( ply:Alive() ) then
		
		local SpawnClass = ply:GetNWString( "SpawnClass", "" )
		
		if ( SpawnClass != "" && SpawnClass == RequestedClass ) then return end
		
		ply:SetNWString( "SpawnClass", RequestedClass )
		
		if ( !disablemessage ) then
			ply:ChatPrint( "Your class will change to '".. baseclass.Get( RequestedClass ).DisplayName .. "' when you respawn" )
		end
		
	else
		self:PlayerJoinClass( ply, RequestedClass, ply:Team() )
	end
	
end

concommand.Add( "changeclass", function( pl, cmd, args ) hook.Call( "PlayerRequestClass", GAMEMODE, pl, tonumber(args[1]) ) end )

local function SeenSplash( ply )
	
	if ( ply.m_bSeenSplashScreen ) then return end
	ply.m_bSeenSplashScreen = true
	
end

concommand.Add( "seensplash", SeenSplash )

--[[-------------------------------------------------------------------------
	PlayerJoinTeam
	To reflect the description on the wiki, this is only a helper function now.
	This will set the team and do some of the things vretta wants to do.
	Does not call OnPlayerChangedTeam, Player:SetTeam will call PlayerChangedTeam
	Therefore all important team changing features are placed in PlayerChangedTeam
---------------------------------------------------------------------------]]
function GM:PlayerJoinTeam( ply, teamid )
	
	local iOldTeam = ply:Team()
	ply:SetNWInt( "OldTeam", iOldTeam )
	
	if ( ply:Alive() ) then
		if ( iOldTeam == TEAM_SPECTATOR || iOldTeam == TEAM_UNASSIGNED ) then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end
	
	ply:SetTeam( teamid )
	
	local Classes = team.GetClass( teamid )
	
	-- Needs to choose class
	if ( Classes != nil && #Classes > 1 ) then
	
		if ( ply:IsBot() || !GAMEMODE.SelectClass ) then
			-- If select class is disabled then select a random one
			GAMEMODE:PlayerRequestClass( ply, math.random( 1, #Classes ), true )
			ply:EnableRespawn()
		else
			
			ply:SetNWBool( "ChangedClass", true )
			
			ply:SendLua( "GAMEMODE:ShowClassChooser( ".. teamid .." )" )
			ply:DisableRespawn()
			
			-- put the player in a VALID class in case they don't choose and get spawned
			player_manager.SetPlayerClass( ply, table.Random( Classes ) )
			
			return
		end
		
	end
	
	-- No class, use default
	if ( (Classes == nil || #Classes == 0) and teamid != TEAM_SPECTATOR ) then
		ErrorNoHalt( "Fretta: no classes found for team: " .. teamid .. "\n" )
		
		player_manager.SetPlayerClass( ply, "player_default_vretta" )
		ply:EnableRespawn()
	end
	
	-- Only one class, use that
	if ( Classes != nil && #Classes == 1 ) then
		
		GAMEMODE:PlayerRequestClass( ply, 1, true )
		ply:EnableRespawn()
	end
end

-- Helper function now, use this in your gamemode. Avoid making changes to internal code!
function GM:OnPlayerChangedTeam( ply, oldTeam, newTeam ) end

-- Originally GM:OnPlayerChangedTeam; which is deprecated
function GM:PlayerChangedTeam( ply, oldteam, newteam )
	
	-- DO NOT SPAWN PLAYERS IN THIS FUNCTION!!
	
	if ( newteam == TEAM_SPECTATOR ) then
		-- For spectator to work, you dont have to spawn them
		-- Simply run BecomeObserver and thats it
		
		ply:KillSilent()--Maybe?
		ply:StripWeapons()
		ply:StripAmmo()
		GAMEMODE:BecomeObserver( ply )
		ply:Freeze( false ) -- Just in case
		player_manager.ClearPlayerClass( ply )
		
	end
	
	if ( oldteam ~= TEAM_CONNECTING ) then
		
		-- I don't know which one is used so lol
		ply.LastTeamChange = RealTime()
		ply.LastTeamSwitch = RealTime()
		ply:SetNWFloat( "RespawnTime", CurTime() + GAMEMODE.MinimumDeathLength )
		
	end
	
	if ( GAMEMODE.PrintTeamChanges ) then
		if (GAMEMODE.TeamBased && newteam == TEAM_UNASSIGNED) then return end
		
		net.Start( "fretta_teamchange" )
			net.WriteEntity( ply )
			net.WriteUInt( oldteam, 16 )
			net.WriteUInt( newteam, 16 )
		net.Broadcast()
	end
	
	-- So SetTeam calls PlayerChangedTeam now
	-- So this function below is only for gamemodes to do additional things!
		-- Not sure if this should be called here?? Don't know
	--GAMEMODE:OnPlayerChangedTeam( ply, iOldTeam, teamid )
end

function GM:PlayerJoinClass( ply, classname, teamid )
	
	ply:SetNWString( "SpawnClass", "" )
	player_manager.SetPlayerClass( ply, classname )
	
	-- If player changed their class then change it here
	if ( ply:GetNWBool( "ChangedClass", false ) ) then
		
		ply:SetNWFloat( "RespawnTime", CurTime() + GAMEMODE.MinimumDeathLength )
		ply:EnableRespawn()
		
		-- Switch back to normal
		ply:SetNWBool( "ChangedClass", false )
	end

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerCanJoinTeam( Player ply, Number teamid )
   Desc: Are we allowed to join a team? Return true if so.
---------------------------------------------------------]]
function GM:PlayerCanJoinTeam( ply, teamid )
	if ( GAMEMODE:TeamHasEnoughPlayers( teamid ) ) then
		ply:ChatPrint( "That team is full!" )
		ply:SendLua("GAMEMODE:ShowTeam()")
		return false
	end
	
	return BaseClass.PlayerCanJoinTeam( self, ply, teamid )
end

function GM:PlayerShouldTakeDamage( ply, attacker )

	if ( GAMEMODE.NoPlayerSelfDamage && IsValid( attacker ) && ply == attacker ) then return false end
	if ( GAMEMODE.NoPlayerDamage ) then return false end
	
	if ( GAMEMODE.NoPlayerTeamDamage && IsValid( attacker ) ) then
		if ( attacker.Team && ply:Team() == attacker:Team() && ply != attacker ) then return false end
	end
	
	if ( IsValid( attacker ) && attacker:IsPlayer() && GAMEMODE.NoPlayerPlayerDamage ) then return false end
	if ( IsValid( attacker ) && !attacker:IsPlayer() && GAMEMODE.NoNonPlayerPlayerDamage ) then return false end
	
	return true

end

function GM:PlayerDeathThink( pl )
	pl.DeathTime = pl.DeathTime or CurTime()
	local timeDead = CurTime() - pl.DeathTime
	
	-- If we're in deathcam mode, promote to a generic spectator mode
	if ( GAMEMODE.DeathLingerTime > 0 && timeDead > GAMEMODE.DeathLingerTime && ( pl:GetObserverMode() == OBS_MODE_FREEZECAM || pl:GetObserverMode() == OBS_MODE_DEATHCAM ) ) then
		GAMEMODE:BecomeObserver( pl )
	end
	
	local pTeam = pl:Team()
	
	-- Dont ever respawn if in spectate mode!!
	if ( pTeam == TEAM_SPECTATOR || ( GAMEMODE.TeamBased && pTeam == TEAM_UNASSIGNED ) ) then return end
	
	-- If we're in a round based game, player NEVER spawns in death think
	if ( GAMEMODE.NoAutomaticSpawning ) then return end
	
	-- Also during a round based game, don't allow respawns between transitioning rounds
	if ( not GAMEMODE:InRound() and GAMEMODE.RoundBased ) then return end
	
	-- The gamemode is holding the player from respawning.
	-- Probably because they have to choose a class..
	if ( not pl:CanRespawn() ) then return end
	
	-- Don't respawn yet - wait for minimum time...
	if ( GAMEMODE.MinimumDeathLength > 0 ) then 
		
		pl:SetNWFloat( "RespawnTime", pl.DeathTime + GAMEMODE.MinimumDeathLength )
		
		if ( timeDead < pl:GetRespawnTime() ) then
			return
		end
		
	end
	
	-- Force respawn
	if ( pl:GetRespawnTime() != 0 && GAMEMODE.MaximumDeathLength ~= 0 && timeDead > GAMEMODE.MaximumDeathLength ) then
		pl:Spawn()
		return
	end
	
	-- Proper automatic team switch spawn
	local iOldTeam = pl:GetNWInt( "OldTeam", -4 )
	
	if ( iOldTeam ~= TEAM_CONNECTING && iOldTeam ~= -4 && pTeam ~= iOldTeam && pl:GetRespawnTime() != 0 && timeDead > GAMEMODE.MinimumDeathLength ) then
		pl:SetNWInt( "OldTeam", pTeam )
		pl:Spawn()
		return
	end
	
	-- We're between min and max death length, player can press a key to spawn.
	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) ) then
		pl:Spawn()
		return
	end
end

-- Removed potential of breaking shit
hook.Add( "PostPlayerDeath", "FrettaSpec", function( ply )
	-- Note, this gets called AFTER DoPlayerDeath.. AND it gets called
	-- for KillSilent too. So if Freezecam isn't set by DoPlayerDeath, we
	-- pick up the slack by setting DEATHCAM here.
	
	if ( ply:GetObserverMode() == OBS_MODE_NONE ) then
		ply:Spectate( OBS_MODE_DEATHCAM )
	end
end)

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	
	ply:CreateRagdoll()
	ply:AddDeaths( 1 )
	
	if ( attacker:IsValid() && attacker:IsPlayer() ) then
		
		if ( attacker == ply ) then
			
			if ( GAMEMODE.TakeFragOnSuicide ) then
				
				attacker:AddFrags( -1 )
				
				if ( GAMEMODE.TeamBased && GAMEMODE.AddFragsToTeamScore ) then
					team.AddScore( attacker:Team(), -1 )
				end
				
			end
			
		else
			
			attacker:AddFrags( 1 )
			
			if ( GAMEMODE.TeamBased && GAMEMODE.AddFragsToTeamScore ) then
				team.AddScore( attacker:Team(), 1 )
			end
			
		end
		
	end
	
	if ( GAMEMODE.EnableFreezeCam && IsValid( attacker ) && attacker != ply ) then
	
		ply:SpectateEntity( attacker )
		ply:Spectate( OBS_MODE_FREEZECAM )
		
	end
	
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerRequestTeam()
		Player wants to change team
---------------------------------------------------------]]
function GM:PlayerRequestTeam( ply, teamid )
	-- oops
	--if ( !GAMEMODE.TeamBased ) then return end
	
	if ( !GAMEMODE.AllowSpectating && teamid == TEAM_SPECTATOR ) then
		ply:ChatPrint( "You can't join spectator!" )
		return
	end
	
	if ( !team.Joinable( teamid ) ) then
		ply:ChatPrint( "You can't join that team" )
		return
	end
	
	if ( !GAMEMODE:PlayerCanJoinTeam( ply, teamid ) ) then
		-- Messages here should be outputted by this function
		return
	end
	
	GAMEMODE:PlayerJoinTeam( ply, teamid )
end

function GM:OnEndOfGame(bGamemodeVote)
	-- This is where you would show extra things before switching to gamemode vote
	-- SET gm.votingdelay to increase the duration of this screen
	
	for k,v in pairs( player.GetAll() ) do
		
		v:Freeze(true)
		v:ConCommand( "+showscores" )
		
	end
	
end

-- Override OnEndOfGame to do any other stuff. like winning music.
function GM:EndOfGame( bGamemodeVote )

	if GAMEMODE.IsEndOfGame then return end

	GAMEMODE.IsEndOfGame = true
	SetGlobalBool( "IsEndOfGame", true )
	
	gamemode.Call("OnEndOfGame", bGamemodeVote)
	
	if ( bGamemodeVote ) then
	
		MsgN( "Starting gamemode voting..." )
		PrintMessage( HUD_PRINTTALK, "Starting gamemode voting..." )
		timer.Simple( GAMEMODE.VotingDelay, function() GAMEMODE:StartGamemodeVote() end )
		
	end

end

function GM:GetWinningFraction()
	if ( !GAMEMODE.GMVoteResults ) then return end
	return GAMEMODE.GMVoteResults.Fraction
end

local function TimeLeft( ply )

	local tl = GAMEMODE:GetGameTimeLeft()
	if ( tl == -1 ) then return end
	
	local Time = util.ToMinutesSeconds( tl )
	
	if ( IsValid( ply ) ) then
		ply:PrintMessage( HUD_PRINTCONSOLE, Time )
	else
		MsgN( Time )
	end
	
end

concommand.Add( "timeleft", TimeLeft )

function GM:CheckTeamBalance()

	local highest

	for id, tm in pairs( team.GetAllTeams() ) do
		if ( id > 0 && id < 1000 && team.Joinable( id ) ) then
			if ( !highest || team.NumPlayers( id ) > team.NumPlayers( highest ) ) then
			
				highest = id
			
			end
		end
	end

	if not highest then return end

	for id, tm in pairs( team.GetAllTeams() ) do
		if ( id ~= highest and id > 0 && id < 1000 && team.Joinable( id ) ) then
			if team.NumPlayers( id ) < team.NumPlayers( highest ) then
				while team.NumPlayers( id ) < team.NumPlayers( highest ) - 1 do
				
					local ply, reason = GAMEMODE:FindLeastCommittedPlayerOnTeam( highest )
					
					ply:Kill()
					GAMEMODE:PlayerJoinTeam( ply, id )
					
					-- Todo: Notify player 'you have been swapped'
					-- This is a placeholder
					PrintMessage(HUD_PRINTTALK, ply:Name().." has been changed to "..team.GetName( id ).." for team balance. ("..reason..")" )
					
				end
			end
		end
	end
	
end

function GM:FindLeastCommittedPlayerOnTeam( teamid )

	local worst
	local worstteamswapper

	for k,v in pairs( team.GetPlayers( teamid ) ) do

		if ( v.LastTeamChange && CurTime() < v.LastTeamChange + 180 && (!worstteamswapper || worstteamswapper.LastTeamChange < v.LastTeamChange) ) then
			worstteamswapper = v
		end

		if ( !worst || v:Frags() < worst:Frags() ) then
			worst = v
		end

	end
	
	if worstteamswapper then
		return worstteamswapper, "They changed teams recently"
	end
	
	return worst, "Least points on their team"
	
end