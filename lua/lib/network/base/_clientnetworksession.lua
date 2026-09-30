local orig__ClientNetworkSession = {}
orig__ClientNetworkSession.on_join_request_reply = ClientNetworkSession.on_join_request_reply


function ClientNetworkSession:on_join_request_reply(...)
	-- Place params in table
	local params = {...}

	-- The `biglobby__` prefixed message carries one extra parameter (`num_players`)
	-- which is placed just before the sender, see NetworkPeer:send() for the details.
	-- A regular 4 player lobby reply has 16 params (15 + sender) and no `num_players`.
	local reply = params[1]
	local sender = params[#params]
	local num_players = sender and type(params[#params - 1]) == "number" and params[#params - 1]

	if num_players then
		-- Remove the extra parameter so the original signature is restored
		table.remove(params, #params - 1)
	end

	-- If the response is `1`(ok), set BigLobby to use host preference or 4 if
	-- a regular lobby (num_players param is falsey).
	if reply == HostNetworkSession.JOIN_REPLY.OK then
		-- Persisting the value across BLT reloads is required, otherwise when you
		-- reach the mission briefing screen, it will use your prefs not hosts.
		Global.BigLobbyPersist.num_players = num_players or 4

		-- Updates state for current BLT instance
		BigLobbyGlobals.num_players = Global.BigLobbyPersist.num_players

		-- The game itself uses `tweak_data.max_players` in a few systems now
		BigLobbyGlobals:apply_max_players()
	end

	-- Pass params on to the original call
	orig__ClientNetworkSession.on_join_request_reply(self, unpack(params))
end
