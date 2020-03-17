
local meta = FindMetaTable( "Player" )
if (!meta) then return end 

-- This isn't Respawn time actually
-- This is the delay before you can respawn
function meta:SetRespawnTime( num )
	
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

-- Used for changing classes right now
-- Use CanRespawn to make sure your gamemode can start once atleast one person has chosen-
-- a class for that team
function meta:DisableRespawn( strReason )
	
	self:SetNWBool( "CanRespawn", false )
	
end

function meta:EnableRespawn()
	
	self:SetNWBool( "CanRespawn", true )
	
end

function meta:CanRespawn()
	return self:GetNWBool( "CanRespawn", false )
end

function meta:IsObserver()
	return ( self:GetObserverMode() > OBS_MODE_NONE )
end
