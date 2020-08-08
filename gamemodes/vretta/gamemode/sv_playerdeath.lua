util.AddNetworkString( "PlayerKilled" )
util.AddNetworkString( "PlayerKilledSelf" )
util.AddNetworkString( "PlayerKilledByPlayer" )

-- Save the custom damage! You DO NOT have to override this!
hook.Add("EntityTakeDamage", "VrettaHandleBonus", function( target, dmginfo )
	
	if ( target:IsPlayer() ) then

		-- On a weapon you assign a bitflag
		-- Then GM:ParseExtendedDeathIcons in client will add the icon to the death notice
		local damageCustom = dmginfo:GetDamageCustom()

		-- first flag is reserved for headshots
		damageCustom = bit.bor( damageCustom, target:LastHitGroup() == HITGROUP_HEAD and 1 or 0 )

		target.m_iDmgCustom = damageCustom

	end

end)

-- TODO: Update NPC deaths as well!

function GM:PlayerDeath( ply, inflictor, attacker )

	-- Don't spawn for at least 2 seconds
	ply.NextSpawnTime = CurTime() + 2
	ply.DeathTime = CurTime()

	ply.m_iDmgCustom = ply.m_iDmgCustom || 0

	-- Run this as early as possible, below have early returns preventing this getting called
	player_manager.RunClass( ply, "Death", inflictor, attacker )

	if ( IsValid( attacker ) && attacker:GetClass() == "trigger_hurt" ) then attacker = ply end

	if ( IsValid( attacker ) && attacker:IsVehicle() && IsValid( attacker:GetDriver() ) ) then
		attacker = attacker:GetDriver()
	end

	if ( !IsValid( inflictor ) && IsValid( attacker ) ) then
		inflictor = attacker
	end

	if ( attacker == ply or (inflictor == attacker and inflictor:GetClass() == "worldspawn") ) then

		net.Start( "PlayerKilledSelf" )
			net.WriteEntity( ply )
			net.WriteString( inflictor:GetClass() )
			net.WriteUInt( ply.m_iDmgCustom, 16 )
		net.Broadcast()

		MsgAll( ply:Nick() .. " suicided!\n" )

	return end

	-- Convert the inflictor to the weapon that they're holding if we can.
	if ( IsValid( inflictor ) && inflictor == attacker && ( inflictor:IsPlayer() || inflictor:IsNPC() ) ) then

		inflictor = inflictor:GetActiveWeapon()
		if ( !IsValid( inflictor ) ) then inflictor = attacker end

	end

	if ( attacker:IsPlayer() ) then

		net.Start( "PlayerKilledByPlayer" )

			net.WriteEntity( ply )
			net.WriteString( inflictor:GetClass() )
			net.WriteEntity( attacker )
			net.WriteUInt( ply.m_iDmgCustom, 16 )

		net.Broadcast()

		MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )

	return end

	-- BUG TODO: incorrectly printing suicides as just death
	net.Start( "PlayerKilled" )

		net.WriteEntity( ply )
		net.WriteString( inflictor:GetClass() )
		net.WriteString( attacker:GetClass() )
		net.WriteUInt( ply.m_iDmgCustom, 16 )

	net.Broadcast()

	MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )

end