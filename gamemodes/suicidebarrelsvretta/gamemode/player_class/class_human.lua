AddCSLuaFile()

local PLAYER = {}

PLAYER.DisplayName			= "Human"
PLAYER.WalkSpeed 			= 170
PLAYER.CrouchedWalkSpeed 	= 0.2
PLAYER.RunSpeed				= 250
PLAYER.DuckSpeed			= 0.4
PLAYER.JumpPower			= 300
PLAYER.DrawTeamRing			= true
PLAYER.MaxHealth			= 100
PLAYER.StartHealth			= 100
PLAYER.StartArmor			= 0

function PLAYER:Loadout()
	
	self.Player:GiveAmmo( 1800, "pistol", true )
	self.Player:Give( "weapon_barrel_killa" )
	self.Player:SetViewOffset( Vector( 0, 0, 64 ) )
	
end

function PLAYER:Death()
	
	self.Player:SetTeam( TEAM_BARREL )
	
end

player_manager.RegisterClass( "Human", PLAYER, "player_default_vretta" )