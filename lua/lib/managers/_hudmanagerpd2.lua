-- This references 4 as in the 4th panel on the UI(one on the furtherest right) by default.
-- Otherwise known as the local players UI panel.
-- By updating this value, we keep that consistency that the player is used to.
HUDManager.PLAYER_PANEL = BigLobbyGlobals:num_player_slots()
if BL2Options then return end


-- `HUDManager:add_teammate_panel` is no longer overridden: the game's version assigns a
-- free player panel itself (including its `_waiting_index` handling) and now uses
-- `set_teammate_callsign(i, ai and tweak_data.max_players + 1 or peer_id)`, so it
-- supports additional peers on its own.
--
-- `HUDManager:_create_teammates_panel` is still overridden because the game's version
-- loops a hardcoded `for i = 1, 4` while checking `i == HUDManager.PLAYER_PANEL`. Since
-- we set `PLAYER_PANEL` to the lobby size, the local player's own panel would never be
-- created. The body below is the game's version with only that loop and the panel
-- spacing changed, the `taken = false` assignment matches the game's
-- `taken = false and is_player` (`false and x` is always false).
function HUDManager:_create_teammates_panel(hud)
	hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
	self._hud.teammate_panels_data = self._hud.teammate_panels_data or {}
	self._teammate_panels = {}
	if hud.panel:child("teammates_panel") then
		hud.panel:remove(hud.panel:child("teammates_panel"))
	end
	local h = self:teampanels_height()
	local teammates_panel = hud.panel:panel({
		name = "teammates_panel",
		h = h,
		y = hud.panel:h() - h,
		halign = "grow",
		valign = "bottom"
	})
	local teammate_w = 204
	local player_gap = 240
	local small_gap = (teammates_panel:w() - player_gap - teammate_w * HUDManager.PLAYER_PANEL) / (HUDManager.PLAYER_PANEL - 1)
	for i = 1, HUDManager.PLAYER_PANEL do
		local is_player = i == HUDManager.PLAYER_PANEL
		--do break end -- unhandled boolean indicator -- Decompile error here, hopefully not causing problems.

		self._hud.teammate_panels_data[i] = {
			taken = false, --this was true, but causes problem with add_teammate_panel() and data.taken, so maybe bad decompile bug from above?
			special_equipments = {}
		}
		local pw = teammate_w + (is_player and 0 or 64)
		local teammate = HUDTeammate:new(i, teammates_panel, is_player, pw)

		if not _G.IS_VR then
			local x = math.floor((pw + small_gap) * (i - 1) + (i == HUDManager.PLAYER_PANEL and player_gap or 0))

			teammate._panel:set_x(math.floor(x))
		end

		table.insert(self._teammate_panels, teammate)
		if is_player then
			teammate:add_panel()
		end
	end
end


-- TODO: nil check added, must have been causing a problem in past, not sure if still valid problem
-- Note: one of the checks used to be inverted (`and not ..:panel()`), which made this
-- error out instead of returning whenever the local player's panel was missing.
local orig__HUDManager = {}
orig__HUDManager.add_weapon = HUDManager.add_weapon
function HUDManager:add_weapon(data)
	local player_panel = self._teammate_panels and self._teammate_panels[HUDManager.PLAYER_PANEL]
	if not player_panel or not player_panel:panel() then
		log("[HUDManager :add_weapon] teammate_panels[HUDManager.PLAYER_PANEL] or teammate_panels[HUDManager.PLAYER_PANEL]:panel() is nil, HUDManager.PLAYER_PANEL = " .. tostring(HUDManager.PLAYER_PANEL))
		return
	end

	orig__HUDManager.add_weapon(self, data)
end


-- The game calls `self._teammate_panels[i]:set_health(data)` without checking if that
-- panel exists, which errors out for peers without a HUD panel assigned.
function HUDManager:set_teammate_health(i, data)
	if i and self._teammate_panels and self._teammate_panels[i] then
		self._teammate_panels[i]:set_health(data)
	end
end
