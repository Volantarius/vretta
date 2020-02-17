AddCSLuaFile()

local PLAYER = {}

PLAYER.DisplayName			= "Barrel"
PLAYER.WalkSpeed 			= 200
PLAYER.CrouchedWalkSpeed 	= 0.2
PLAYER.RunSpeed				= 100
PLAYER.DuckSpeed			= 0.4
PLAYER.JumpPower			= 0
PLAYER.PlayerModel			= "models/props_c17/oildrum001_explosive.mdl"
PLAYER.MaxHealth			= 1
PLAYER.StartHealth			= 1
PLAYER.StartArmor			= 0
PLAYER.DisableFootsteps		= true
PLAYER.DrawTeamRing			= false
PLAYER.UseVMHands			= false

function PLAYER:SetModel()
	
	util.PrecacheModel( self.PlayerModel )
	self.Player:SetModel( self.PlayerModel )
	
end

function PLAYER:Loadout()
	
end

function PLAYER:Spawn()

	self.Player.NextTaunt = CurTime() + 1;
	self.Player.CanExplodeAfter = CurTime() + 1;
	
	self.Player:StripWeapons()
	self.Player:SetViewOffset( Vector( 0, 0, 42 ) )

end

function PLAYER:Death()
	
	local boom = ents.Create( "env_explosion" )
	boom:SetPos( self.Player:GetPos() )
	boom:SetOwner( self.Player )
	boom:Spawn()
	boom:SetKeyValue( "iMagnitude", "150" )
	boom:Fire( "Explode", 0, 0 )
	
end

function PLAYER:KeyPress( key )
	
	if !self.Player:Alive() then return end
	
	if( key == IN_ATTACK and self.Player.CanExplodeAfter and CurTime() >= self.Player.CanExplodeAfter ) then
		
		self.Player.CanExplode = false
		self.Player:EmitSound( "Grenade.Blip" )
		
		timer.Simple( .5, function() if IsValid( self.Player ) and self.Player:Alive() then self.Player:EmitSound( "Grenade.Blip" ) end end )
		timer.Simple( 1, function() if IsValid( self.Player ) and self.Player:Alive() then self.Player:EmitSound( "Grenade.Blip" ) end end )
		timer.Simple( 1.5, function() if IsValid( self.Player ) and self.Player:Alive() then self.Player:EmitSound( "Weapon_CombineGuard.Special1" ) end end )
		timer.Simple( 2, function() if IsValid( self.Player ) and self.Player:Alive() then self.Player:Kill() end end )
		
		self.Player.CanExplodeAfter = CurTime() + 2.5
		
	end
 
	if( key == IN_ATTACK2 and self.Player.NextTaunt and CurTime() >= self.Player.NextTaunt ) then
		self.Player:EmitSound( table.Random( TAUNTS ), 100, 140 )
		self.Player.NextTaunt = CurTime() + 2
	end
		
end

player_manager.RegisterClass( "Barrel", PLAYER, "player_default_vretta" )