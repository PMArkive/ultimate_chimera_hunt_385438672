//Thanks Overv!

/*-------------------------------------------------------------------------------------------------------------------------
	chat.AddText([ Player ply,] Colour colour, string text, Colour colour, string text, ... )
	Returns: nil
	In Object: None
	Part of Library: chat
	Available On: Server
-------------------------------------------------------------------------------------------------------------------------*/

if SERVER then
	chat = { }
	function chat.AddText( ... )
		arg = {...};
		if ( type( arg[1] ) == "Player" ) then ply = arg[1] end
		
		net.Start( "AddText" )
			net.WriteFloat( #arg )
			for _, v in pairs( arg ) do
				if ( type( v ) == "string" ) then
					net.WriteString( v )
				elseif ( type ( v ) == "table" ) then
					net.WriteFloat( v.r )
					net.WriteFloat( v.g )
					net.WriteFloat( v.b )
					net.WriteFloat( v.a )
				end
			end
		net.Send( player.GetAll() )
	end
else
	net.Receive( "AddText", function()
		local argc = net.ReadFloat( )
		local args = { };
		for i = 1, argc / 2, 1 do
			table.insert( args,Color( net.ReadFloat( ), net.ReadFloat( ), net.ReadFloat( ), net.ReadFloat( ) ) )
			table.insert( args, net.ReadString( ) )
		end
		
		chat.AddText( unpack( args ) )
	end )
end