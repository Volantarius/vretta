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
	
	return ply:CanUseFlashlight()
end

-- Add a few different settings, like no fall damaage, real, fretta, etc
function GM:GetFallDamage( ply, flFallSpeed )
	
	if ( GAMEMODE.RealisticFallDamage ) then
		return flFallSpeed / 8
	end
	
	--[[
	if( GetConVarNumber( "mp_falldamage" ) > 0 ) then -- realistic fall damage is on
		return ( flFallSpeed - 526.5 ) * ( 100 / 396 ) -- the Source SDK value
	end
	]]
	
	return 10
	
end

--[[---------------------------------------------------------
	Name: gamemode:ScalePlayerDamage( ply, hitgroup, dmginfo )
	Desc: Scale the damage based on being shot in a hitbox
		 Return true to not take damage
-----------------------------------------------------------]]
function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )

-- This fucking this does NOT work correctly
-- please avoid and use the GM:EntityTakeDamage instead!!!

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
   Name: gamemode:GravGunPunt( )
   Desc: We're about to punt an entity (primary fire).
		 Return true if we're allowed to.
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
-----------------------------------------------------------]]
function GM:PhysgunPickup( ply, ent )
	
	-- Fretta disable physgun
	if ( !GAMEMODE.EnablePhysgun:GetBool() ) then return false end
	
	-- Don't pick up persistent props
	if ( ent:GetPersistent() ) then return false end
	
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
		if ( EntClass == "func_physbox" && ent:HasSpawnFlags( SF_PHYSBOX_MOTIONDISABLED ) ) then return false  end
		
		-- If the physics object is frozen by the mapper, don't allow us to move it.
		if ( string.find( EntClass, "prop_" ) && ( ent:HasSpawnFlags( SF_PHYSPROP_MOTIONDISABLED ) || ent:HasSpawnFlags( SF_PHYSPROP_PREVENT_PICKUP ) ) ) then return false end
		
		-- Allow physboxes, but get rid of all other func_'s (ladder etc)
		if ( EntClass != "func_physbox" && string.find( EntClass, "func_" ) ) then return false end

	
	end
	
	return true
	
end

--[[---------------------------------------------------------
	Name: gamemode:OnPhysgunFreeze( weapon, phys, ent, player )
	Desc: The physgun wants to freeze a prop
-----------------------------------------------------------]]
function GM:OnPhysgunFreeze( weapon, phys, ent, ply )
	
	-- Fretta disable physgun freeze mode
	if ( !GAMEMODE.PhysgunFreeze:GetBool() ) then return false end
	
	-- Object is already frozen (!?)
	if ( !phys:IsMoveable() ) then return false end
	if ( ent:GetUnFreezable() ) then return false end
	
	phys:EnableMotion( false )
	
	-- With the jeep we need to pause all of its physics objects
	-- to stop it spazzing out and killing the server.
	if ( ent:GetClass() == "prop_vehicle_jeep" ) then
	
		local objects = ent:GetPhysicsObjectCount()
		
		for i = 0, objects - 1 do
		
			local physobject = ent:GetPhysicsObjectNum( i )
			physobject:EnableMotion( false )
		
		end
	
	end

	-- Add it to the player's frozen props
	ply:AddFrozenPhysicsObject( ent, phys )
	
	return true

end

--[[---------------------------------------------------------
	Name: gamemode:OnPhysgunReload( weapon, player )
	Desc: The physgun wants to freeze a prop
-----------------------------------------------------------]]
function GM:OnPhysgunReload( weapon, ply )

	ply:PhysgunUnfreeze( weapon )

end