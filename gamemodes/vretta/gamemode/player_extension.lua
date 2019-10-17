
local meta = FindMetaTable( "Player" )
if (!meta) then return end 

-- This isn't Respawn time actually
-- This is the delay before you can respawn
function meta:SetRespawnTime( num )
	
	--debug.Trace()
	
	self.m_iSpawnTime = num
	
	self:SetNWFloat( "SpawnTime", num )
	
end

function meta:GetRespawnTime( num )
	
	local time = self:GetNWFloat( "SpawnTime", GAMEMODE.MinimumDeathLength )
	
	if ( time == 0 ) then
		return GAMEMODE.MinimumDeathLength
	end
	
	return time
end

function meta:DisableRespawn( strReason )
	
	--debug.Trace()
	
	-- Enabled just for reference
	self.m_bCanRespawn = false
	
	self:SetNWBool( "CanRespawn", false )
	
end

function meta:EnableRespawn()
	
	--debug.Trace()
	
	-- Enabled just for reference
	self.m_bCanRespawn = true
	
	self:SetNWBool( "CanRespawn", true )
	
end

function meta:CanRespawn()
	
	return self:GetNWBool( "CanRespawn", false )
	
end

function meta:IsObserver()
	return ( self:GetObserverMode() > OBS_MODE_NONE )
end

function meta:UpdateNameColor()
	
	if ( GAMEMODE.SelectColor ) then
		self:SetNWString( "NameColor", self:GetInfo( "cl_vretta_playercolor" ) )
	end
	
end
