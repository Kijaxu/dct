#!/usr/bin/lua

require("dcttestlibs")
require("dct")

-- create a player group
local grp = Group(4, {
	["id"] = 9,
	["name"] = "VMFA251 - Enfield 1-1",
	["coalition"] = coalition.side.BLUE,
	["exists"] = true,
})

local unit1 = Unit({
	["name"] = "pilot1",
	["exists"] = true,
	["desc"] = {
		["typeName"] = "FA-18C_hornet",
		["attributes"] = {
			["Airplane"] = true,
		},
	},
}, grp, "bobplayer")

local grp2 = Group(1, {
	["id"] = 10,
	["name"] = "VMFA251 - Enfield 1-2",
	["coalition"] = coalition.side.BLUE,
	["exists"] = true,
})

local unit2 = Unit({
	["name"] = "pilot2",
	["exists"] = true,
	["desc"] = {
		["typeName"] = "FA-18C_hornet",
		["attributes"] = {
			["Airplane"] = true,
		},
	},
}, grp2, "tomplayer")


-- Since groupmenu is added by the Theater, we just get a Theater
-- instance and then cook up an event to call the theater DCS
-- event handler with.

local testcmds = {
	{
		["event"] = {
			["id"]        = world.event.S_EVENT_BIRTH,
			["initiator"] = unit1,
		},
		["assert"] = true,
		["expect"] = "Please read the loadout limits in the briefing"..
			" and use the F10 Menu to validate your loadout before"..
			" departing.",
	}, {
		["event"] = {
			["id"]        = world.event.S_EVENT_BIRTH,
			["initiator"] = unit2,
		},
		["assert"] = true,
		["expect"] = "Please read the loadout limits in the briefing"..
			" and use the F10 Menu to validate your loadout before"..
			" departing.",
	},
}

local function main()
	local theater = dct.Theater()
	_G.dct.theater = theater
	dctstubs.setModelTime(50)
	theater:exec(50)
	for _, data in ipairs(testcmds) do
		trigger.action.setmsgbuffer(data.expect)
		theater:onEvent(data.event)
		trigger.action.chkmsgbuffer()
	end

	local uzi11 = theater:getAssetMgr():getAsset(grp:getName())

	local enum = require("dct.enum")
	assert(uzi11.payloadlimits[enum.weaponCategory.AG] == 60,
		"uzi11 doesn't have the expected AG payload limit")
	return 0
end

os.exit(main())
