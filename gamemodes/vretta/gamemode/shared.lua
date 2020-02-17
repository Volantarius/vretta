--[[
	shared.lua - Shared Component
	-----------------------------------------------------
	This is the shared component of your gamemode, a lot of the game variables
	can be changed from here.
]]

DEFINE_BASECLASS( "gamemode_base" )

include( "player_class/player_default_vretta.lua" )

include( "player_extension.lua" )

fretta_voting = CreateConVar( "fretta_voting", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Allow/Dissallow voting" )

GM.Name 	= "Simple Game Base"
GM.Author 	= "Anonymous"
GM.Email 	= ""
GM.Website 	= "www.garry.tv"
GM.Help		= "No Help Available"

GM.TeamBased = true					-- Team based game or a Free For All game?
GM.AllowAutoTeam = true				-- Allow auto-assign?
GM.AllowSpectating = true			-- Allow people to spectate during the game?

GM.SecondsBetweenTeamSwitches = 10	-- The minimum time between each team change?

GM.GameLength = 15					-- The overall length of the game
GM.RoundLimit = -1					-- Maximum amount of rounds to be played in round based games
GM.VotingDelay = 10					-- Delay between end of game, and vote. if you want to display any extra screens before the vote pops up
GM.ShowTeamName = true				-- Show the team name on the HUD

GM.NoPlayerSuicide = false			-- Set to true if players should not be allowed to commit suicide.
GM.NoPlayerDamage = false			-- Set to true if players should not be able to damage each other.
GM.NoPlayerSelfDamage = false		-- Allow players to hurt themselves?
GM.NoPlayerTeamDamage = true		-- Allow team-members to hurt each other?
GM.NoPlayerPlayerDamage = false 	-- Allow players to hurt each other?
GM.NoNonPlayerPlayerDamage = false 	-- Allow damage from non players (physics, fire etc)
GM.NoPlayerFootsteps = false		-- When true, all players have silent footsteps
GM.PlayerCanNoClip = false			-- When true, players can use noclip without sv_cheats
GM.TakeFragOnSuicide = true			-- -1 frag on suicide

GM.MaximumDeathLength = 0			-- Player will repspawn if death length > this (can be 0 to disable)
GM.MinimumDeathLength = 2			-- Player has to be dead for at least this long
GM.AutomaticTeamBalance = false     -- Teams will be periodically balanced 
GM.ForceJoinBalancedTeams = true	-- Players won't be allowed to join a team if it has more players than another team
GM.AddFragsToTeamScore = false		-- Adds player's individual kills to team score (must be team based)

GM.NoAutomaticSpawning = false		-- Players don't spawn automatically when they die, some other system spawns them
GM.RoundBased = false				-- Round based, like CS
GM.RoundLength = 30					-- Round length, in seconds
GM.RoundPreStartTime = 5			-- Preperation time before a round starts
GM.RoundPostLength = 8				-- Seconds to show the 'x team won!' screen at the end of a round
GM.RoundEndsWhenOneTeamAlive = true	-- CS Style rules

GM.EnableFreezeCam = false			-- TF2 Style Freezecam
GM.DeathLingerTime = 4				-- The time between you dying and it going into spectator mode, 0 disables
GM.DeathLingerTimeMax = 10 			-- The maximum time you can spectate while dead, 0 will disable

GM.SelectModel = true               -- Can players use the playermodel picker in the F1 menu?
GM.SelectColor = false				-- Can players modify the colour of their name? (ie.. no teams)

GM.PlayerRingSize = CreateConVar( "fretta_gm_ringsize", "48", { FCVAR_REPLICATED }, "How big are the colored rings under the player's feet" )
GM.HudSkin = "SimpleSkin"			-- The Derma skin to use for the HUD components
GM.SuicideString = "died"			-- The string to append to the player's name when they commit suicide.
GM.DeathNoticeDefaultColor = Color( 255, 128, 0 ) -- Default colour for entity kills
GM.DeathNoticeTextColor = color_white -- colour for text ie. "died", "killed"

GM.ValidSpectatorModes = { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING } -- The spectator modes that are allowed
GM.ValidSpectatorEntities = { "player" }	-- Entities we can spectate, players being the obvious default choice.
GM.CanOnlySpectateOwnTeam = false			-- You can only spectate players on your own team

--[[-------------------------------------------------------------------------
	NEW Misc Settings
---------------------------------------------------------------------------]]

GM.PrintTeamChanges = true 			-- Show that a player has changed their team (ie.. suicide barrels)

GM.RealisticFallDamage = false		-- Set to true if you want realistic fall damage instead of the fix 10 damage.
GM.PlayerDeathSounds = true 		-- Play the default death sounds, alternatively override with custom ones

GM.PlayerPickupItems = CreateConVar( "fretta_gm_pickupitems", "0", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow players to pickup items with USE key" )

GM.EnablePhysgun = CreateConVar( "fretta_gm_physgun_enable", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow the physics gun to pick up anything at all" )
GM.LimitedPhysgun = CreateConVar( "fretta_gm_physgun_limited", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Set the physics gun to only pick up valid objects (Like sandbox mode)" )
GM.PhysgunFreeze = CreateConVar( "fretta_gm_physgun_freeze", "0", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow the physics gun to freeze objects" )

TEAM_GREEN 		= 1
TEAM_ORANGE 	= 2
TEAM_BLUE 		= 3
TEAM_RED 		= 4

--[[---------------------------------------------------------
   Name: gamemode:CreateTeams()
   Desc: Set up all your teams here. Note - HAS to be shared.
---------------------------------------------------------]]
function GM:CreateTeams()
	
	team.SetUp( TEAM_SPECTATOR, "Spectators", Color( 200, 200, 200 ), true )
	team.SetSpawnPoint( TEAM_SPECTATOR, "worldspawn" )
	
	if ( !GAMEMODE.TeamBased ) then return end
	
	team.SetUp( TEAM_GREEN, "Green Team", Color( 70, 230, 70 ), true )
	team.SetSpawnPoint( TEAM_GREEN, "info_player_start" ) -- The list of entities can be a table
	
	team.SetUp( TEAM_ORANGE, "Orange Team", Color( 255, 200, 50 ) )
	team.SetSpawnPoint( TEAM_ORANGE, "info_player_start" )
	
	team.SetUp( TEAM_BLUE, "Blue Team", Color( 80, 150, 255 ) )
	team.SetSpawnPoint( TEAM_BLUE, "info_player_start" )
	
	team.SetUp( TEAM_RED, "Red Team", Color( 255, 80, 80 ) )
	team.SetSpawnPoint( TEAM_RED, "info_player_start" )
end

function GM:InGamemodeVote()
	return GetGlobalBool( "InGamemodeVote", false )
end

--[[-------------------------------------------------------------------------
	gamemode:KeyPress( Player ply, Number key )
	Runs the player's class function
---------------------------------------------------------------------------]]
function GM:KeyPress( ply, key )
	
	if ( player_manager.RunClass( ply, "KeyPress", key ) ) then return true end
	
end

--[[-------------------------------------------------------------------------
	gamemode:KeyRelease( Player ply, Number key )
	Runs the player's class function
---------------------------------------------------------------------------]]
function GM:KeyRelease( ply, key )
	
	if ( player_manager.RunClass( ply, "KeyRelease", key ) ) then return true end
	
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerFootstep( Player ply, Vector pos, Number foot, String sound, Float volume, CReceipientFilter filter )
   Desc: Player's feet makes a sound, this also calls the player's class Footstep function.
		 If you want to disable all footsteps set GM.NoPlayerFootsteps to true.
		 If you want to disable footsteps on a class, set Class.DisableFootsteps to true.
---------------------------------------------------------]]
function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter ) 

	if( GAMEMODE.NoPlayerFootsteps || !ply:Alive() || ply:Team() == TEAM_SPECTATOR || ply:IsObserver() ) then
		return true
	end
	
	local pClass = player_manager.GetPlayerClass( ply )
	local gClass = baseclass.Get( pClass )
	
	if ( gClass == nil ) then return end
	
	if ( gClass.DisableFootsteps ) then
		return true
	end
	
	BaseClass.PlayerFootstep( self, ply, pos, foot, sound, volume, filter )
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerNoClip( player, bool )
   Desc: Player pressed the noclip key, return true if
		  the player is allowed to noclip, false to block
---------------------------------------------------------]]
function GM:PlayerNoClip( pl, on )
	
	-- Allow noclip if we're in single player or have cheats enabled
	return (( GAMEMODE.PlayerCanNoClip || game.SinglePlayer() || GetConVar( "sv_cheats" ):GetBool() ) && ( IsValid(pl) && pl:Alive() ))
end

--[[---------------------------------------------------------
   Name: gamemode:GravGunPunt( )
   Desc: We're about to punt an entity (primary fire).
		 Return true if we're allowed to.
	SANDBOX RIP
-----------------------------------------------------------]]
function GM:GravGunPunt( ply, ent )

	if ( ent:IsValid() && ent.GravGunPunt ) then
		return ent:GravGunPunt( ply )
	end

	return BaseClass.GravGunPunt( self, ply, ent )
	
end

--[[---------------------------------------------------------
   Name: gamemode:GravGunPickupAllowed( )
   Desc: Return true if we're allowed to pickup entity
   SANDBOX RIP
-----------------------------------------------------------]]
function GM:GravGunPickupAllowed( ply, ent )

	if ( ent:IsValid() && ent.GravGunPickupAllowed ) then
		return ent:GravGunPickupAllowed( ply )
	end

	return BaseClass.GravGunPickupAllowed( self, ply, ent )
	
end

--[[---------------------------------------------------------
   Name: gamemode:PhysgunPickup( )
   Desc: Return true if player can pickup entity
   SANDBOX RIP
-----------------------------------------------------------]]
function GM:PhysgunPickup( ply, ent )
	
	-- Fretta disable physgun
	if ( !GAMEMODE.EnablePhysgun:GetBool() ) then return false end
	
	if ( ent:IsValid() && ent.PhysgunPickup ) then
		return ent:PhysgunPickup( ply )
	end
	
	-- Some entities specifically forbid physgun interaction
	if ( ent.PhysgunDisabled ) then return false end
	
	local EntClass = ent:GetClass()
	
	-- Never pick up players
	if ( EntClass == "player" ) then return false end
	
	if ( GAMEMODE.LimitedPhysgun:GetBool() ) then
		
		if ( string.find( EntClass, "prop_dynamic" ) ) then return false end
		if ( string.find( EntClass, "prop_door" ) ) then return false end
		
		-- Don't move physboxes if the mapper logic says no
		if ( EntClass == "func_physbox" && ent:HasSpawnFlags( SF_PHYSBOX_MOTIONDISABLED ) ) then return false end
		
		-- If the physics object is frozen by the mapper, don't allow us to move it.
		if ( string.find( EntClass, "prop_" ) && ( ent:HasSpawnFlags( SF_PHYSPROP_MOTIONDISABLED ) || ent:HasSpawnFlags( SF_PHYSPROP_PREVENT_PICKUP ) ) ) then return false end
		
		-- Allow physboxes, but get rid of all other func_'s (ladder etc)
		if ( EntClass != "func_physbox" && string.find( EntClass, "func_" ) ) then return false end

	
	end
	
	return true
	
end

--[[---------------------------------------------------------
   Name: gamemode:TeamHasEnoughPlayers( Number teamid )
   Desc: Return true if the team has too many players.
		 Useful for when forced auto-assign is on.
---------------------------------------------------------]]
function GM:TeamHasEnoughPlayers( teamid )

	if teamid == TEAM_SPECTATOR then return false end

	local PlayerCount = team.NumPlayers( teamid )

	-- Don't let them join a team if it has more players than another team
	if ( GAMEMODE.ForceJoinBalancedTeams ) then
	
		for id, tm in pairs( team.GetAllTeams() ) do
			if ( id > 0 && id < 1000 && team.NumPlayers( id ) < PlayerCount && team.Joinable(id) ) then return true end
		end
		
	end
	
	return false
	
end

--[[---------------------------------------------------------
   Name: gamemode:GetTimeLimit()
   Desc: Returns the time limit of a game in seconds, so you could
		 make it use a cvar instead. Return -1 for unlimited.
		 Unlimited length games can be changed using vote for
		 change.
---------------------------------------------------------]]
function GM:GetTimeLimit()

	if( GAMEMODE.GameLength > 0 ) then
		return (GAMEMODE.GameLength * 60) + GAMEMODE.RoundPreStartTime
	end
	
	return -1
	
end

--[[---------------------------------------------------------
   Name: gamemode:GetGameTimeLeft()
   Desc: Get the remaining time in seconds.
---------------------------------------------------------]]
function GM:GetGameTimeLeft()

	local EndTime = GAMEMODE:GetTimeLimit()
	if ( EndTime == -1 ) then return -1 end
	
	return EndTime - CurTime()

end


function util.ToMinutesSeconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60
	
    return string.format("%02d:%02d", minutes, math.floor(seconds))
end

function util.ToMinutesSecondsMilliseconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60
	
	local milliseconds = math.floor(seconds % 1 * 100)
	
    return string.format("%02d:%02d.%02d", minutes, math.floor(seconds), milliseconds)
end

function timer.SimpleEx(delay, action, ...)
	if ... == nil then
		timer.Simple(delay, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Simple(delay, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end

function timer.CreateEx(timername, delay, repeats, action, ...)
	if ... == nil then
		timer.Create(timername, delay, repeats, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Create(timername, delay, repeats, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end