-- Instead of overriding the whole method, the original `init` is run and only the panel
-- height is corrected. The game creates the player slot panels for
-- `1 .. tweak_data.max_players` peers itself now and its chat colour lookup already
-- falls back to the last available colour, but the panel height is still calculated
-- from a hardcoded 4 slots (`h = text_font_size * 4 + 20`).
local orig__HUDMissionBriefing = {
	init = HUDMissionBriefing.init
}


function HUDMissionBriefing:init(...)
	orig__HUDMissionBriefing.init(self, ...)

	-- Singleplayer and any early return of the original init won't have the panel
	if self._singleplayer or not self._ready_slot_panel then
		return
	end

	local text_font_size = tweak_data.menu.pd2_small_font_size
	local num_player_slots = BigLobbyGlobals:num_player_slots()

	-- Adjust height of panel to accomodate for the amount of player slots
	self._ready_slot_panel:set_h(text_font_size * num_player_slots + 20)
end
