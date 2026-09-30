local orig_BaseNetworkSession = {
	check_peer_preferred_character = BaseNetworkSession.check_peer_preferred_character,
	on_network_stopped = BaseNetworkSession.on_network_stopped
}


-- Modified to add the BigLobby state reset on top of the original behaviour.
-- `BaseNetworkSession:on_network_stopped` and `BaseNetworkSession:_get_peer_outfit_versions_str`
-- are no longer re-implemented here, the game loops `tweak_data.max_players` itself now.
function BaseNetworkSession:on_network_stopped(...)
	-- Call Original Code
	orig_BaseNetworkSession.on_network_stopped(self, ...)

	-- Resets host lobby size preference when leaving their lobby
	Global.BigLobbyPersist.num_players = nil
	-- Update this variable in case the player left from lobby screen (doesn't reload the mod)
	BigLobbyGlobals.num_players = BigLobbyGlobals.num_players_settings--Global.BigLobbyPersist.num_players
	-- Restore `tweak_data.max_players` to our own lobby size preference
	BigLobbyGlobals:apply_max_players()
end


-- Modified to provide all peers with a character, regardless of free characters.
function BaseNetworkSession:check_peer_preferred_character(preferred_character)
	local all_characters = clone(CriminalsManager.character_names())
	local character

	-- Only get a character through the normal method if one is availiable
	if #self._peers_all < #all_characters then
		-- Call Original Code
		character = orig_BaseNetworkSession.check_peer_preferred_character(self, preferred_character)
	end

	-- Get a new character if all have already been taken
	if character == nil then
		-- Allow them to use their preferred character first
		local preferreds = string.split(preferred_character, " ")
		for _, preferred in ipairs(preferreds) do
			if table.contains(all_characters, preferred) then
				return preferred
			end
		end

		-- Fallback to just getting a random character
		character = all_characters[math.random(#all_characters)]
	end

	return character
end
