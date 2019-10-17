-- Fretta differences! This uses GMOD13's new class system! Very cool!
-- Again made to avoid conflicts with Fretta itself, gamemodes will require changes to GM13 standards
AddCSLuaFile()

local PLAYER = {}

PLAYER.DisplayName				= "Vretta Default Class"

PLAYER.WalkSpeed					= 400		-- How fast to move when not running
PLAYER.RunSpeed						= 600		-- How fast to move when running
PLAYER.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching

PLAYER.DuckSpeed					= 0.3		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed				= 0.3		-- How fast to go from ducking, to not ducking

PLAYER.JumpPower					= 200		-- How powerful our jump should be

PLAYER.CanUseFlashlight		= true		-- Can we use the flashlight

PLAYER.MaxHealth					= 100		-- Max health we can have
PLAYER.StartHealth				= 100		-- How much health we start with
PLAYER.StartArmor					= 0			-- How much armour we start with

PLAYER.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
PLAYER.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers				= true		-- Automatically swerves around other players

PLAYER.UseVMHands					= true		-- Uses viewmodel hands

-- Fretta features!
PLAYER.DrawTeamRing 			= true
PLAYER.DisableFootsteps		= false

function PLAYER:SetupDataTables()
end

--
-- Called when the class object is created (shared)
--
function PLAYER:Init()
end


--
-- Called serverside only when the player spawns
--
function PLAYER:Spawn()	
	
	local col = self.Player:GetInfo( "cl_vretta_playercolor" )
	
	self.Player:SetPlayerColor( Vector(col) )
	self.Player:SetWeaponColor( Vector(col) )
	
	if ( GAMEMODE.TeamBased and !GAMEMODE.SelectColor ) then
		local col = team.GetColor( self.Player:Team() )
		local vcol = Vector(col.r/255, col.g/255, col.b/255)
		
		self.Player:SetPlayerColor( vcol )
		self.Player:SetWeaponColor( vcol )
	end
	
end


function PLAYER:Loadout()
	
	self.Player:Give( "weapon_pistol" )
	self.Player:GiveAmmo( 255, "Pistol", true )
	
end

-- NOTE: removed think function from player classes
-- If it really is required and is shared, then use a hook instead

-- Clientside ONLY

-- Serverside ONLY
function PLAYER:Death() end

-- Shared
function PLAYER:KeyPress( key ) end
function PLAYER:KeyRelease( key ) end


function PLAYER:SetModel()

	local cl_vretta_playermodel = self.Player:GetInfo( "cl_vretta_playermodel" )
	local modelname = player_manager.TranslatePlayerModel( cl_vretta_playermodel )
	util.PrecacheModel( modelname )
	self.Player:SetModel( modelname )

end

player_manager.RegisterClass( "player_default_vretta", PLAYER, "player_default" )
