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

function GM:Think()
	-- Check if the round or game is over from the time
	if( !GAMEMODE.IsEndOfGame && ( !GAMEMODE.RoundBased || ( GAMEMODE.RoundBased && GAMEMODE:CanEndRoundBasedGame() ) ) && CurTime() >= GAMEMODE.GetTimeLimit() ) then
		GAMEMODE:EndOfGame( true )
	end
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerInitialSpawn( Player ply )
   Desc: Our very first spawn in the game.
---------------------------------------------------------]]
function GM:PlayerInitialSpawn( pl )
	pl:SetTeam( TEAM_UNASSIGNED )
	pl:SetNWBool( "FirstSpawn", true )
	
	pl:UpdateNameColor()
	
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

end

function GM:PlayerDisconnected( pl )
	
	table.insert( GAMEMODE.ReconnectedPlayers, pl:UniqueID() )
	
	BaseClass.PlayerDisconnected(self, pl)
	
end  

function GM:ShowHelp( pl )

	pl:SendLua( "GAMEMODE:ShowHelp()" )
	
end

function GM:PlayerSpawn( pl ) 
	
	pl:UpdateNameColor()
	
	-- The player never spawns straight into the game in Fretta
	-- They spawn as a spectator first (during the splash screen and team picking screens)
	
	if ( pl:GetNWBool( "FirstSpawn", true ) ) then
		
		pl:SetNWBool( "FirstSpawn", false )
		
		if ( pl:IsBot() ) then
			
			GAMEMODE:AutoTeam( pl )
			
			-- The bot doesn't send back the 'seen splash' command, so fake it.
			-- Specifically in team based, we spawn the players at the beginning so we dont need to spawn them now
			if ( !GAMEMODE.TeamBased && !GAMEMODE.NoAutomaticSpawning ) then
				pl:Spawn()
			end
			
		else
			
			-- Set the player to spectator and yeah...
			-- This seems to be called before the splashscreen thing :()
			
			pl:SetTeam( TEAM_SPECTATOR )
			pl:Spectate( OBS_MODE_ROAMING )
			GAMEMODE:BecomeObserver( pl )
			
		end
		
		return
		
	end
	
	-- Dont spawn instead go into spectator mode
	-- Also if team based don't allow unassigned player spawns
	if ( pl:Team() == TEAM_SPECTATOR || ( GAMEMODE.TeamBased && pl:Team() == TEAM_UNASSIGNED) ) then
		GAMEMODE:BecomeObserver( pl )
		return
	end
	
	local Classes = team.GetClass( pl:Team() ) -- Returns nil if no classes
	local SpawnClass = pl:GetNWString( "SpawnClass", "" )
	
	-- Player requested a new class, so we set that here
	-- Elsewhere the class gets changed with PlayerJoinTeam
	
	if ( Classes != nil and SpawnClass != "" ) then
		
		player_manager.SetPlayerClass( pl, SpawnClass )
		
		pl:SetNWString( "SpawnClass", "" )
	end
	
	-- Stop observer mode
	pl:UnSpectate()
	
	-- Get the player class just in case nothing was changed on last spawn!
	local pClass = player_manager.GetPlayerClass( pl )
	local gClass = baseclass.Get( pClass )
	
	if ( gClass.DrawTeamRing ) then pl:SetNWBool( "DrawRing", true ) else pl:SetNWBool( "DrawRing", false ) end
	
	player_manager.OnPlayerSpawn( pl )
	player_manager.RunClass( pl, "Spawn" )
	
	-- Set player model
	hook.Call( "PlayerSetModel", GAMEMODE, pl )
	-- Set the player model before setting up the hand models
	pl:SetupHands()
	
	-- Call item loadout function
	hook.Call( "PlayerLoadout", GAMEMODE, pl )
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
	
	-- Kill the player preventing them from spectating in a weird player class
	ply:KillSilent()
	
end

concommand.Add( "seensplash", SeenSplash )

--[[-------------------------------------------------------------------------
	PlayerJoinTeam
	
	Please use this function whenever you change the player's team
	This will set the team regardless of autoteam,
	will set to spectator mode CORRECTLY, and give the option to choose
	a team class if enabled.
---------------------------------------------------------------------------]]
function GM:PlayerJoinTeam( ply, teamid )
	
	local iOldTeam = ply:Team()
	ply:SetNWInt( "OldTeam", iOldTeam )
	
	if ( ply:Alive() ) then
		if ( iOldTeam == TEAM_SPECTATOR || (iOldTeam == TEAM_UNASSIGNED && GAMEMODE.TeamBased) ) then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end
	
	ply:SetTeam( teamid )
	ply.LastTeamSwitch = RealTime()
	
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
	
	if ( teamid == TEAM_SPECTATOR ) then
		-- Remove all classes for spectators
		player_manager.ClearPlayerClass( ply )
	end
	
	gamemode.Call("OnPlayerChangedTeam", ply, iOldTeam, teamid )
end

function GM:PlayerJoinClass( ply, classname, teamid )
	
	ply:SetNWString( "SpawnClass", "" )
	player_manager.SetPlayerClass( ply, classname )
	
	-- If player changed their class then change it here
	if ( ply:GetNWBool( "ChangedClass", false ) ) then
		local OldTeam = ply:GetNWInt( "OldTeam", teamid )
		
		ply.DeathTime = CurTime()
		GAMEMODE:OnPlayerChangedTeam( ply, OldTeam, teamid )
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
	
	if ( SERVER && !BaseClass.PlayerCanJoinTeam( self, ply, teamid ) ) then 
		return false 
	end
	
	if ( GAMEMODE:TeamHasEnoughPlayers( teamid ) ) then
		ply:ChatPrint( "That team is full!" )
		ply:SendLua("GAMEMODE:ShowTeam()")
		return false
	end
	
	return true
	
end

function GM:OnPlayerChangedTeam( ply, oldteam, newteam )
	
	if ( newteam == TEAM_SPECTATOR ) then
		-- For spectator to work, you dont have to spawn them
		-- Simply run BecomeObserver and thats it
		
		ply:StripWeapons()
		ply:StripAmmo()
		GAMEMODE:BecomeObserver( ply )
		
		--ply:ConCommand( "cl_spec_mode "..OBS_MODE_CHASE )
		--ply:Spectate( OBS_MODE_CHASE ) --Default add auto player spectate
		
	elseif ( oldteam == TEAM_SPECTATOR ) then
		
		-- If we're changing from spectator, join the game
		if ( !GAMEMODE.NoAutomaticSpawning ) then
			ply:Spawn()
		end
		
	elseif ( oldteam ~= TEAM_SPECTATOR ) then
		
		ply.LastTeamChange = CurTime()
		
	else
		
		-- If we're straight up changing teams just hang
		--  around until we're ready to respawn onto the 
		--  team that we chose
		
	end
	
	--PrintMessage( HUD_PRINTTALK, Format( "%s joined '%s'", ply:Nick(), team.GetName( newteam ) ) )
	
	-- Send net msg for team change
 	
 	if ( GAMEMODE.PrintTeamChanges ) then
 		net.Start( "fretta_teamchange" )
			net.WriteEntity( ply )
			net.WriteUInt( oldteam, 16 )
			net.WriteUInt( newteam, 16 )
	  net.Broadcast()
 	end
 	
end

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
	
	-- Dont ever respawn if in spectate mode!!
	if ( pl:Team() == TEAM_SPECTATOR || ( GAMEMODE.TeamBased && pl:Team() == TEAM_UNASSIGNED ) ) then return end
	
	-- If we're in a round based game, player NEVER spawns in death think
	if ( GAMEMODE.NoAutomaticSpawning ) then return end
	
	-- Also during a round based game, don't allow respawns between transitioning rounds
	if ( !GAMEMODE:InRound() and GAMEMODE.RoundBased ) then return end
	
	-- The gamemode is holding the player from respawning.
	-- Probably because they have to choose a class..
	if ( !pl:CanRespawn() ) then return end
	
	-- Don't respawn yet - wait for minimum time...
	if ( GAMEMODE.MinimumDeathLength > 0 ) then 
		
		pl:SetNWFloat( "RespawnTime", pl.DeathTime + GAMEMODE.MinimumDeathLength )
		
		if ( timeDead < pl:GetRespawnTime() ) then
			return
		end
		
	end
	
	-- Force respawn
	if ( pl:GetRespawnTime() != 0 && GAMEMODE.MaximumDeathLength != 0 && timeDead > GAMEMODE.MaximumDeathLength ) then
		pl:Spawn()
		return
	end
	
	-- We're between min and max death length, player can press a key to spawn.
	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) ) then
		pl:Spawn()
		return
	end
	
end

function GM:PostPlayerDeath( ply )

	-- Note, this gets called AFTER DoPlayerDeath.. AND it gets called
	-- for KillSilent too. So if Freezecam isn't set by DoPlayerDeath, we
	-- pick up the slack by setting DEATHCAM here.
	
	if ( ply:GetObserverMode() == OBS_MODE_NONE ) then
		ply:Spectate( OBS_MODE_DEATHCAM )
	end
	
	player_manager.RunClass( ply, "Death" )
end

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

function GM:StartSpectating( ply )

	if ( !GAMEMODE:PlayerCanJoinTeam( ply ) ) then return end
	
	ply:StripWeapons()
	ply:StripAmmo()
	GAMEMODE:PlayerJoinTeam( ply, TEAM_SPECTATOR )
	GAMEMODE:BecomeObserver( ply )

end

function GM:EndSpectating( ply )
	
	if ( !GAMEMODE:PlayerCanJoinTeam( ply ) ) then return end
	
	GAMEMODE:PlayerJoinTeam( ply, TEAM_UNASSIGNED )
	
	ply:KillSilent()
	
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerRequestTeam()
		Player wants to change team
---------------------------------------------------------]]
function GM:PlayerRequestTeam( ply, teamid )
	
	if ( !GAMEMODE.TeamBased && GAMEMODE.AllowSpectating ) then
		
		if ( teamid == TEAM_SPECTATOR ) then
			GAMEMODE:StartSpectating( ply )
		else
			GAMEMODE:EndSpectating( ply )
		end
		
		return
		
	end
	
	return BaseClass.PlayerRequestTeam(self, ply, teamid)
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