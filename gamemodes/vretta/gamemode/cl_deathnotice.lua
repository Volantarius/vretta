include( 'vgui/vgui_gamenotice.lua' )

local hud_deathnotice_time = CreateClientConVar( "hud_deathnotice_time", "6", true, false )
local hud_deathnotice_limit = CreateClientConVar( "hud_deathnotice_limit", "5", true, false )

-- Fallbacks, really need many more icons
language.Add( "env_laser", "Laser" )
language.Add( "env_explosion", "Explosion" )
language.Add( "func_door", "Door" )
language.Add( "func_door_rotating", "Door" )
language.Add( "trigger_hurt", "Hazard" )
language.Add( "func_rotating", "Hazard" )
language.Add( "entityflame", "Fire" )

local Color_Icon = Color( 255, 80, 0, 255 )

killicon.AddFont( "csheadshot",		"CSKillIcons",	"D",	Color_Icon )
killicon.AddFont( "csdefault",		"CSKillIcons",	"C",	Color_Icon )

killicon.AddAlias( "prop_physics_multiplayer", "prop_physics" )
killicon.AddAlias( "worldspawn", "csdefault" )

local function CreateDeathNotify()

	local x, y = ScrW(), ScrH()

	g_DeathNotify = vgui.Create( "DNotify" )
	
	g_DeathNotify:SetPos( 0, 25 )
	g_DeathNotify:SetSize( x - ( 25 ), y )
	g_DeathNotify:SetAlignment( 9 )
	g_DeathNotify:SetSkin( GAMEMODE.HudSkin )
	g_DeathNotify:SetLife( hud_deathnotice_time:GetInt() )
	g_DeathNotify:ParentToHUD()

end

hook.Add( "InitPostEntity", "CreateDeathNotify", CreateDeathNotify )

local function RecvPlayerKilledByPlayer( length )

	local victim 	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker 	= net.ReadEntity()
	local dmgCust 	= net.ReadUInt(16)

	if ( !IsValid( attacker ) ) then return end
	if ( !IsValid( victim ) ) then return end
	
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker, dmgCust )
end
	
net.Receive( "PlayerKilledByPlayer", RecvPlayerKilledByPlayer )


local function RecvPlayerKilledSelf( length )

	local victim 	= net.ReadEntity()
	local inflictor	= net.ReadString()--new
	local dmgCust 	= net.ReadUInt(16)

	if ( !IsValid( victim ) ) then return end

	GAMEMODE:AddSuicideDeathNotice( victim, inflictor, dmgCust )

end
	
net.Receive( "PlayerKilledSelf", RecvPlayerKilledSelf )


local function RecvPlayerKilled( length )

	local victim 	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker 	= "#" .. net.ReadString()
	local dmgCust 	= net.ReadUInt(16)

	if ( !IsValid( victim ) ) then return end
	
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker, dmgCust )

end
	
net.Receive( "PlayerKilled", RecvPlayerKilled )

local function RecvPlayerKilledNPC( length )

	local victim 	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker 	= net.ReadEntity()

	if ( !IsValid( attacker ) ) then return end
			
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )

end
	
net.Receive( "PlayerKilledNPC", RecvPlayerKilledNPC )


local function RecvNPCKilledNPC( length )

	local victim 	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker 	= "#" .. net.ReadString()
		
	GAMEMODE:AddDeathNotice( victim, inflictor, attacker )

end

net.Receive( "NPCKilledNPC", RecvNPCKilledNPC )

--[[---------------------------------------------------------
   Name: gamemode:ParseExtendedDeathIcons( customdmg, victim, inflictor, attacker )
   Desc: You can now parse SetCustomDamage to use bitflags to add extended death notice info.
   
   THIS IS THE ONLY FUNCTION YOU NEED TO OVERRIDE!
---------------------------------------------------------]]
function GM:ParseExtendedDeathIcons( pnl, customdmg, victim, inflictor, attacker )

	--256 possible

	if ( bit.band( customdmg, 1 ) > 0 ) then
		pnl:AddIcon( "csheadshot" )
	end

	--[[ Some examples
	if ( bit.band( customdmg, 2 ) > 0 ) then
		pnl:AddIcon( "ricochet" )
	end

	if ( bit.band( customdmg, 4 ) > 0 ) then
		pnl:AddIcon( "instagib" )
	end
	]]

end

--[[---------------------------------------------------------
   Name: gamemode:AddDeathNotice( Victim, Weapon, Attacker )
   Desc: Adds an death notice entry
---------------------------------------------------------]]
function GM:AddDeathNotice( victim, inflictor, attacker, customdmg )

	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )
	
	pnl:AddText( attacker )
	pnl:AddIcon( inflictor )

	if ( customdmg and customdmg > 0 ) then
		GAMEMODE:ParseExtendedDeathIcons( pnl, customdmg, victim, inflictor, attacker )
	end

	pnl:AddText( victim )
	
	g_DeathNotify:AddItem( pnl )

end

function GM:AddSuicideDeathNotice( victim, inflictor, customdmg )

	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )
	
	if ( inflictor ~= "player" ) then
		pnl:AddIcon( inflictor )
	else
		pnl:AddIcon( "csdefault" )
	end
	
	if ( customdmg and customdmg > 0 ) then
		GAMEMODE:ParseExtendedDeathIcons( pnl, customdmg, victim, inflictor )
	end

	pnl:AddText( victim )
	
	pnl:AddText( GAMEMODE.SuicideString )
	
	g_DeathNotify:AddItem( pnl )

end

function GM:AddPlayerAction( ... )
	
	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )

	for k, v in ipairs({...}) do
		pnl:AddText( v )
	end
	
	-- The rest of the arguments should be re-thought.
	-- Just create the notify and add them instead of trying to fit everything into this function!???
	
	g_DeathNotify:AddItem( pnl )
	
end
