include( "vgui/vgui_vote.lua" )

g_PlayableGamemodes = {}
g_bGotGamemodesTable = false

function RcvPlayableGamemodes( length )

	g_PlayableGamemodes = net.ReadTable()
	g_bGotGamemodesTable = true

end

net.Receive( "PlayableGamemodes", function() pcall(RcvPlayableGamemodes) end )

local GMChooser = nil
local function GetVoteScreen()
	LocalPlayer():ConCommand("-score")
	if ( IsValid( GMChooser ) ) then return GMChooser end

	GMChooser = vgui.Create( "VoteScreen" )
	return GMChooser

end

function GM:ShowGamemodeChooser()

	local votescreen = GetVoteScreen()
	votescreen:ChooseGamemode()

end

function GM:GamemodeWon( mode )

	local votescreen = GetVoteScreen()
	votescreen:FlashItem( mode )

end

function GM:ChangingGamemode( mode, map )

	local votescreen = GetVoteScreen()
	votescreen:FlashItem( map )

end

function GM:ShowMapChooserForGamemode( gmname )

	local votescreen = GetVoteScreen()
	votescreen:ChooseMap( gmname )

end
