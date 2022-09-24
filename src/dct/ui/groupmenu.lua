-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles applying a F10 menu UI to player groups
-- Assumptions:
-- It is assumed each player group consists of a single player
-- aircraft due to issues with the game.
--
-- Notes:
--   Once a menu is added to a group it does not need to be added
--   again, which is why we need to track which group ids have had
--   a menu added. The reason why this cannot be done up front on
--   mission start is because the the group does not exist until at
--   least one player occupies a slot. We must add the menu upon
--   object creation.

local utils    = require("libs.utils")
local dctenum  = require("dct.enum")
local Theater  = require("dct.Theater")
local loadout  = require("dct.ui.loadouts")
local msncodes = require("dct.ui.missioncodes")
local Logger   = dct.Logger.getByName("UI")
local addmenu  = missionCommands.addSubMenuForGroup
local addcmd   = missionCommands.addCommandForGroup

local menus = {}
function menus.createMenu(asset)
	local gid  = asset.groupId
	local name = asset.name

	if asset.uimenus ~= nil then
		Logger:debug("createMenu - group(%s) already had menu added", name)
		return
	end

	Logger:debug("createMenu - adding menu for group: %s", name)

	asset.uimenus = {}

	local padmenu = addmenu(gid, "Scratch Pad", nil)
	for k, v in pairs({
		["DISPLAY"] = dctenum.uiRequestType.SCRATCHPADGET,
		["SET"] = dctenum.uiRequestType.SCRATCHPADSET}) do
		addcmd(gid, k, padmenu, Theater.playerRequest,
			{
				["name"]   = name,
				["type"]   = v,
			})
	end

	addcmd(gid, "Theater Update", nil, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.THEATERSTATUS,
		})

	local msnmenu = addmenu(gid, "Mission", nil)
	local rqstmenu = addmenu(gid, "Request", msnmenu)
	for k, v in utils.sortedpairs(asset.ato) do
		addcmd(gid, k, rqstmenu, Theater.playerRequest,
			{
				["name"]   = name,
				["type"]   =
					dctenum.uiRequestType.MISSIONREQUEST,
				["value"]  = v,
			})
	end

	local joinmenu = addmenu(gid, "Join", msnmenu)
	addcmd(gid, "Use Scratch Pad Value", joinmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.MISSIONJOIN,
			["value"]  = nil,
		})

	local codemenu = addmenu(gid, "Input Code (F1-F10)", joinmenu)
	msncodes.addMissionCodes(gid, name, codemenu)

	addcmd(gid, "Briefing", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.MISSIONBRIEF,
		})
	addcmd(gid, "Status", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.MISSIONSTATUS,
		})
	addcmd(gid, "Abort", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.MISSIONABORT,
			["value"]  = dctenum.missionAbortType.ABORT,
		})
	addcmd(gid, "Rolex +30", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = dctenum.uiRequestType.MISSIONROLEX,
			["value"]  = 30*60,  -- seconds
		})
	loadout.addmenu(asset, nil, Theater.playerRequest)
end

return menus
