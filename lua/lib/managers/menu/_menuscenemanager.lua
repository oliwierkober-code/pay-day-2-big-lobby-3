-- The game's `MenuSceneManager:_setup_lobby_characters` and
-- `MenuSceneManager:hide_all_lobby_characters` now loop `tweak_data.max_players` and
-- `MenuSceneManager:_select_lobby_character_pose` now picks its pose with
-- `peer_id % #lobby_poses + 1`, so those no longer need to be re-implemented here.
--
-- `_setup_lobby_characters` is kept because the game's `_characters_rotation` table only
-- holds 8 yaw values, which makes more than 8 lobby characters overlap. The version below
-- builds the table dynamically (two ranges: one for the other peers and one used by the
-- local peer, see `set_lobby_character_out_fit`) and spreads the characters outwards from
-- the center.
--
-- `set_lobby_character_out_fit` is still wrapped because the game indexes that rotation
-- table with a hardcoded `4` as the halfway point (`(is_me and 4 or 0) + i`).


function MenuSceneManager:_setup_lobby_characters()
	local num_player_slots = BigLobbyGlobals:num_player_slots()

	-- Original Code --
	if self._lobby_characters then
		for _, unit in ipairs(self._lobby_characters) do
			self:_delete_character_mask(unit)
			World:delete_unit(unit)
		end
	end
	self._lobby_characters = {}
	self._characters_offset = Vector3(0, -200, -130)
	-- End Original Code --

	-- Code changed was:
	-- Replacing hardcoded 4 with variable num_player_slots
	-- Replacing the local masks variable from hardcoded table to dynamically generated via loop
	-- Replacing self._characters_rotation from hardcoded table to dynamically generated via loop
	self._characters_rotation = {}

	-- Dynamically building a range of rotations, used below and by MenuSceneManager:set_lobby_character_out_fit
	local min = -130
	local max = -56
	local range = min - max
	local steps = range / (num_player_slots-1)

	-- The first half of rotations is for all peers except local peer:
	for i = 1, num_player_slots do
		self._characters_rotation[i] = (((i-1) * steps) + max)
	end

	-- The second half of rotations is what the local peer uses based on their peer id:
	for i = 1, num_player_slots do
		self._characters_rotation[i+num_player_slots] = (((i-1) * steps) + max)
	end

	-- Dummy string filled with "dallas" because that's what it was originally
	local masks = {}
	for i = 1, num_player_slots do
		masks[i] = "dallas"
	end

	-- This added logic should alter positioning of players to start at the center
	-- and expand outwards as the player count grows.
	local offset = 0 -- Starting offset
	local peer_rotations = #self._characters_rotation/2
	-- eg 4/2->2, 5/2->2.5->3, 6/2->3, 7/2->3.5->4
	local center_index = math.ceil(peer_rotations/2)
	local function get_new_index(index)
		local is_even = index%2==0
		local new_index = is_even and center_index + offset or center_index - offset
		-- After adding one to the left and one to the right, increase the offset
		-- Unless starting index is odd, then increase straight after(no left/right)
		if not is_even then offset = offset + 1 end

		return new_index
	end

	-- Only code changed here was replacing a hardcoded value of 4 with the variable
	-- num_player_slots and adding the local function above for set_yaw_pitch_roll
	local mvec = Vector3()
	local math_up = math.UP
	local pos = Vector3()
	local rot = Rotation()
	for i = 1, num_player_slots do
		mrotation.set_yaw_pitch_roll(rot, self._characters_rotation[get_new_index(i)], 0, 0)
		mvector3.set(pos, self._characters_offset)
		mvector3.rotate_with(pos, rot)
		mvector3.set(mvec, pos)
		mvector3.negate(mvec)
		mvector3.set_z(mvec, 0)
		mrotation.set_look_at(rot, mvec, math_up)
		local unit_name = tweak_data.blackmarket.characters.locked.menu_unit
		local unit = World:spawn_unit(Idstring(unit_name), pos, rot)
		self:_init_character(unit, i)
		self:set_character_mask(tweak_data.blackmarket.masks[ masks[i] ].unit, unit, nil, masks[i])
		table.insert(self._lobby_characters, unit)
		self:set_lobby_character_visible(i, false, true)
	end
end


-- I run the original method, but then need to correct a hardcoded 4 which requires running
-- a bunch of logic again. Should be safe.
local orig__MenuSceneManager = {}
orig__MenuSceneManager.set_lobby_character_out_fit = MenuSceneManager.set_lobby_character_out_fit
function MenuSceneManager:set_lobby_character_out_fit(i, outfit_string, rank)
	local num_player_slots = BigLobbyGlobals:num_player_slots()

	orig__MenuSceneManager.set_lobby_character_out_fit(self, i, outfit_string, rank)

	local unit = self._lobby_characters[i]

	-- The original returns early when the peer or character doesn't exist
	if not unit or not alive(unit) then
		return
	end

	local session = managers.network:session()
	local is_me = session and i == session:local_peer():id()
	local mvec = Vector3()
	local math_up = math.UP
	local pos = Vector3()
	local rot = Rotation()

	-- Only the hardcoded 4 here is changed to a variable
	-- The 4 refers to halfway point of the rotation table, not player count.
	mrotation.set_yaw_pitch_roll(rot, self._characters_rotation[(is_me and num_player_slots or 0) + i], 0, 0)

	-- Original Code --
	mvector3.set(pos, self._characters_offset)
	if is_me then
		mvector3.set_y(pos, mvector3.y(pos) + 100)
	end
	mvector3.rotate_with(pos, rot)
	mvector3.set(mvec, pos)
	mvector3.negate(mvec)
	mvector3.set_z(mvec, 0)
	mrotation.set_look_at(rot, mvec, math_up)
	unit:set_position(pos)
	unit:set_rotation(rot)
	self:set_lobby_character_visible(i, true)
	-- End Original Code --
end
