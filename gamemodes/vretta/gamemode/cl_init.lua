DEFINE_BASECLASS( "gamemode_base" )

function surface.CreateLegacyFont(font, size, weight, antialias, additive, name, shadow, outline, blursize)
	surface.CreateFont(name, {font = font, size = size, weight = weight, antialias = antialias, additive = additive, shadow = shadow, outline = outline, blursize = blursize})
end

-- Create new seperate player model and color variables, so that we dont override sandbox's variables

local vretta_player_model = CreateConVar( "cl_vretta_playermodel", "alyx.mdl",  { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "Set your player model in vretta")
local vretta_player_color = CreateConVar( "cl_vretta_playercolor", "255 255 0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "Set your player color in vretta")

include( 'shared.lua' )
include( 'cl_splashscreen.lua' )
include( 'cl_selectscreen.lua' )
include( 'cl_gmchanger.lua' )
include( 'cl_help.lua' )
include( 'skin.lua' )
include( 'vgui/vgui_hudlayout.lua' )
include( 'vgui/vgui_hudelement.lua' )
include( 'vgui/vgui_hudbase.lua' )
include( 'vgui/vgui_hudcommon.lua' )
include( 'cl_hud.lua' )
include( 'cl_deathnotice.lua' )
include( 'cl_scores.lua' )
include( 'cl_notify.lua' )

language.Add( "env_laser", "Laser" )
language.Add( "env_explosion", "Explosion" )
language.Add( "func_door", "Door" )
language.Add( "func_door_rotating", "Door" )
language.Add( "trigger_hurt", "Hazard" )
language.Add( "func_rotating", "Hazard" )
language.Add( "worldspawn", "Gravity" )
language.Add( "prop_physics", "Prop" )
language.Add( "prop_physics_respawnable", "Prop" )
language.Add( "prop_physics_multiplayer", "Prop" )
language.Add( "entityflame", "Fire" )

surface.CreateLegacyFont( "Trebuchet MS", 69, 700, true, false, "FRETTA_HUGE" )
surface.CreateLegacyFont( "Trebuchet MS", 69, 700, true, false, "FRETTA_HUGE_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 40, 700, true, false, "FRETTA_LARGE" )
surface.CreateLegacyFont( "Trebuchet MS", 40, 700, true, false, "FRETTA_LARGE_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 19, 700, true, false, "FRETTA_MEDIUM" )
surface.CreateLegacyFont( "Trebuchet MS", 19, 700, true, false, "FRETTA_MEDIUM_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 16, 700, true, false, "FRETTA_SMALL" )

surface.CreateLegacyFont( "Trebuchet MS", ScreenScale( 10 ), 700, true, false, "FRETTA_NOTIFY", true )

surface.CreateLegacyFont( "csd", ScreenScale(30), 500, true, true, "CSKillIcons" )
surface.CreateLegacyFont( "csd", ScreenScale(60), 500, true, true, "CSSelectIcons" )

CreateClientConVar( "cl_spec_mode", "5", true, true )

function GM:Initialize()
	
	-- from the base gamemode run the disable scoreboard on start
	BaseClass.Initialize( self )
	
end

local function SeenSplashLocal()
	if ( GAMEMODE.TeamBased ) then
		GAMEMODE:ShowTeam()
	else
		GAMEMODE:ShowHelp()
	end
end

concommand.Add( "seensplashlocal", function(ply, cmd, args, argStr) SeenSplashLocal() end )

hook.Add("InitPostEntity", "VrettaShowSplash", function()
	-- This was changed to make the server send the showteam or showhelp things
	-- AFTER the player sees the splashscreen, since they were getting called so
	-- early that they couldn't join the game.
	timer.Simple(0.5, function() GAMEMODE:ShowSplash() end)
end)

local CircleMat = Material( "SGM/playercircle" )

function GM:DrawPlayerRing( pPlayer )
	
	if ( !IsValid( pPlayer ) ) then return end
	if ( !pPlayer:GetNWBool( "DrawRing", false ) ) then return end
	if ( !pPlayer:Alive() ) then return end
	
	local trace = {}
	trace.start 	= pPlayer:GetPos() + Vector(0,0,50)
	trace.endpos 	= trace.start + Vector(0,0,-300)
	trace.filter 	= pPlayer
	
	local tr = util.TraceLine( trace )
	
	if not tr.HitWorld then
		tr.HitPos = pPlayer:GetPos()
	end
	
	local color = table.Copy( team.GetColor( pPlayer:Team() ) )
	color.a = 40
	
	render.SetMaterial( CircleMat )
	render.DrawQuadEasy( tr.HitPos + tr.HitNormal, tr.HitNormal, GAMEMODE.PlayerRingSize:GetInt(), GAMEMODE.PlayerRingSize:GetInt(), color )	
	
end

hook.Add( "PrePlayerDraw", "DrawPlayerRing", function( ply ) GAMEMODE:DrawPlayerRing( ply ) end ) 

function GM:OnSpawnMenuOpen()
	RunConsoleCommand( "lastinv" ) -- Fretta is derived from base and has no spawn menu, so give it a use, make it lastinv.
end

-- This is to send the server to run a command
function GM:PlayerBindPress( pl, bind, down )

	-- Redirect binds to the spectate system
	-- NEW: We only want to allow spec switching in certain spec modes!
	-- Deathcam and freezecam should be switched out of by vretta with a timer using minimum death linger time
	
	if ( pl:Alive() ) then return false end
	
	local mode = pl:GetObserverMode()
	
	if ( mode > OBS_MODE_NONE && down ) then
		
		if ( bind == "+jump" ) then 	RunConsoleCommand( "spec_mode" )	end
		
		if ( mode < OBS_MODE_ROAMING ) then
			if ( bind == "+attack" ) then	RunConsoleCommand( "spec_next" )	end
			if ( bind == "+attack2" ) then	RunConsoleCommand( "spec_prev" )	end
		end
		
	end

	return false

end

function GM:TeamChangeNotification( ply, oldteam, newteam )
	if( ply && ply:IsValid() ) then
		local nick = ply:Nick()
		
		if ( LocalPlayer() == ply and nick == "unconnected" ) then return end
		
		local oldTeamColor = team.GetColor( oldteam )
		local newTeamName = team.GetName( newteam )
		local newTeamColor = team.GetColor( newteam )
		
		if( newteam == TEAM_SPECTATOR ) then
			chat.AddText( oldTeamColor, nick, color_white, " is now spectating" ) 
		else
			chat.AddText( oldTeamColor, nick, color_white, " joined ", newTeamColor, newTeamName )
		end
		
		chat.PlaySound()
	end
end
net.Receive( "fretta_teamchange", function( um )  if ( GAMEMODE ) then GAMEMODE:TeamChangeNotification( net.ReadEntity(), net.ReadUInt(16), net.ReadUInt(16) ) end end )
