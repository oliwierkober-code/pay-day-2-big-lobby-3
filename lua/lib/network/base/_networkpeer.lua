-- Store original functions from the ones we modify
local orig_NetworkPeer = {
	send = NetworkPeer.send
}


function NetworkPeer:send(func_name, ...)
	-- In biglobby mode if the func is matched, call the prefixed version instead
	if not BigLobbyGlobals:is_small_lobby() and BigLobbyGlobals.network_handler_funcs[func_name] then
		-- `join_request_reply` is sent by the host state classes (`HostStateInGame` and
		-- `HostStateInLobby`) with the exact same parameter list as the regular game,
		-- so the extra `num_players` value is appended here. It matches the
		-- `biglobby__join_request_reply` definition in the network settings pdmod
		-- (16 params) and is picked up by our `ClientNetworkSession:on_join_request_reply`
		-- wrapper on the receiving side.
		if func_name == "join_request_reply" then
			local params = {...}

			-- `HostStateBase:_send_request_denied` also replies with this message, but
			-- it doesn't go through NetworkPeer.send() and it carries a shorter/denied
			-- reply. Anything that is not the full accepted reply is sent untouched.
			if #params >= 15 then
				params[#params + 1] = BigLobbyGlobals:num_player_slots()

				orig_NetworkPeer.send(self, 'biglobby__' .. func_name, unpack(params))

				return
			end
		else
			func_name = 'biglobby__' .. func_name
		end
	end

	-- Call Original Code
	orig_NetworkPeer.send(self, func_name, ...)
end
