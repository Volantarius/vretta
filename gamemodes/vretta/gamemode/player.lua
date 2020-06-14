DEFINE_BASECLASS( "gamemode_base" )

--[[---------------------------------------------------------
   Name: gamemode:CanPlayerSuicide( Player ply )
   Desc: Is the player allowed to commit suicide?
---------------------------------------------------------]]
function GM:CanPlayerSuicide( ply )
	
	if( ply:Team() == TEAM_SPECTATOR ) then
		return false -- no suicide in spectator mode
	end
	
	return !GAMEMODE.NoPlayerSuicide
end 

--[[---------------------------------------------------------
   Name: gamemode:PlayerSwitchFlashlight( Player ply, Bool on )
   Desc: Can we turn our flashlight on or off?
---------------------------------------------------------]]
function GM:PlayerSwitchFlashlight( ply, on )
	
	if ( ply:Team() == TEAM_SPECTATOR || ply:Team() == TEAM_CONNECTING ) then
		return false
	end
	
	return BaseClass.PlayerSwitchFlashlight( self, ply, on )
end

-- Ripped from SASS
local fall_fatal = 1100
local fall_maxsafe = 580
local fall_damage = 100 / ( fall_fatal - fall_maxsafe )

function GM:GetFallDamage( ply, flFallSpeed )
	if ( GAMEMODE.RealisticFallDamage or GAMEMODE.RealisticFallDamage == 1 ) then
		-- Fretta, backwards compatable!
		return flFallSpeed / 8
		
	elseif ( GAMEMODE.RealisticFallDamage == 2 ) then
		-- SASS mimics CS:S fall damage!
		return math.max( (speed - fall_maxsafe) * fall_damage * 1.25, 0 )
		
	elseif ( GAMEMODE.RealisticFallDamage == 3 ) then
		-- the Source SDK value
		return ( flFallSpeed - 526.5 ) * ( 100 / 396 )
		
	end
	
	return 10
end

--[[---------------------------------------------------------
	Name: gamemode:PlayerDeathSound()
	Desc: Return true to not play the default sounds
-----------------------------------------------------------]]
function GM:PlayerDeathSound()
	return !GAMEMODE.PlayerDeathSounds
end

--[[---------------------------------------------------------
	Name: gamemode:AllowPlayerPickup( ply, object )
-----------------------------------------------------------]]
function GM:AllowPlayerPickup( ply, object )
	
	-- Should the player be allowed to pick this object up (using ENTER)?
	-- If no then return false. Default is HELL YEAH
	
	return GAMEMODE.PlayerPickupItems:GetBool()
end

--[[---------------------------------------------------------
	Name: gamemode:OnPhysgunFreeze( weapon, phys, ent, player )
	Desc: The physgun wants to freeze a prop
-----------------------------------------------------------]]
function GM:OnPhysgunFreeze( weapon, phys, ent, ply )
	
	-- Fretta disable physgun freeze mode
	if ( !GAMEMODE.PhysgunFreeze:GetBool() ) then return false end
	
	-- If allowed use the base freeze stuff HORRAY
	return BaseClass.OnPhysgunFreeze( self, weapon, phys, ent, ply )

end