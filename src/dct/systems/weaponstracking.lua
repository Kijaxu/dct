--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Weapons impact tracking system
--]]

local class    = require("libs.namedclass")
local vector   = require("dct.libs.vector")
local Command  = require("dct.Command")
local Logger   = dct.Logger.getByName("WpnTracker")

local TRACKED_WEAPON_FREQ = 1.0 -- seconds

--[[
-- is the weapon an anti-radiation missile
local function isWpnARM(wpn)
	local wpndesc = wpn:getDesc()
	return (wpndesc.category == Weapon.Category.MISSILE and
		wpndesc.missileCategory == Weapon.MissileCategory.OTHER and
		wpndesc.guidance == Weapon.GuidanceType.RADAR_PASSIVE)
end
--]]

-- Only units that are not air defence and are firing
-- weapons with HE warheads are considered
local function isWpnValid(event)
	if event.initiator:hasAttribute("Air Defence") then
		return false
	end

	local wpndesc = event.weapon:getDesc()
	local allowedmsltypes = {
		[Weapon.MissileCategory.CRUISE] = true,
		[Weapon.MissileCategory.OTHER]  = true,
	}
	if wpndesc.category == Weapon.Category.MISSILE and
	   allowedmsltypes[wpndesc.missileCategory] == nil then
	   return false
	end

	if wpndesc.warhead.type ~= Weapon.WarheadType.HE then
		return false
	end
	return true
end

-- return the distance in meters from the center of a blast from an
-- explosive charge of mass(kg) that will cause leathal damage
-- Assume a normalized TNT equivalent mass
-- sources:
--   https://www.fema.gov/pdf/plan/prevent/rms/428/fema428_ch4.pdf
--   https://www.fourmilab.ch/etexts/www/effects/eonw_3.pdf
local function calcRadiusFromMass(mass)
	return math.ceil(11.338 * math.pow(mass, .281))
end

local DCTWeapon = class("DCTWeapon")
function DCTWeapon:__init(wpn, initiator)
	self.weapon      = wpn
	self.type        = wpn:getTypeName()
	self.shootername = initiator:getName()
	self.desc        = wpn:getDesc()
	self.lethaldist  = calcRadiusFromMass(self.desc.warhead.explosiveMass)
	self.maxdist     = 1.3 * self.lethaldist
	self:update()
end

function DCTWeapon:isExist()
	return self.weapon:isExist()
end

function DCTWeapon:update()
	local pos = self.weapon:getPosition()

	self.pos  = vector.Vector3D(pos.p)
	self.dir  = vector.Vector3D(pos.x)
	self.vel  = vector.Vector3D(self.weapon:getVelocity())
	self.time = timer.getTime()
end

function DCTWeapon:getImpactPoint()
	local timediff = timer.getTime() - self.time

	-- find impact point
	local impactpt = land.getIP(self.pos:raw(), self.dir:raw(),
		self.vel:magnitude()*timediff)
	if impactpt == nil then
		-- use the velocity vector to translate the last
		-- sampled point to where the point would have been
		-- half-way between the last sample and now
		impactpt = self.pos + (self.vel * (timediff / 2))
	end
	self.impactpt = impactpt
end

function DCTWeapon:getEffectsVolume()
	self:getImpactPoint()
	local vol = {}
	vol.id     = world.VolumeType.SPHERE
	vol.params = {
		point  = self.impactpt:raw(),
		radius = self.maxdist,
	}
	return vol
end

local function handleobject(obj, wpndata)
	-- only process if the object matches a specific set of critera
	--   not sure what this means.
	--
	-- verify if the impact point and the unit's location can see
	--  eachother, make sure to raise the y axis by 1 meter so
	--  that we don't immediatly run into land
	--
	-- determine distance from impact point
	-- determine Pk, probability of kill
	-- draw random number and determine if the unit should be
	--  killed or suppressed/stunned
	--
	-- killing uses
	--    trigger.action.explosion(point1, power)
	--  and can be applied per unit. The power of the explosion is
	--  defined as the kilogram TNT equivalent, so we should just be able
	--  to take the explosive mass in the weapon's description table.
	--
	-- suppression is really just turning off the AI and can only
	--  be done at the group level. Since it affects the entire
	--  group we shouldn't turn off the entire group's AI until
	--  some percentage of the group is affected. Also simply
	--  queuing up to turn a group AI on after a period of time
	--  doesn't account for the AI already being off/on. Instead
	--  a moral and hold-down timer can be used to prevent flapping
	--  of the AI.
end


local tracked = {}
local TrackWeaponsCmd = class("TrackWeaponsCmd", Command)
function TrackWeaponsCmd:__init()
	self.name = "TrackWeaponsCmd"
	self.prio = Command.PRIORITY.WEAPON
end

function TrackWeaponsCmd:execute(time)
	for id, wpn in pairs(tracked) do
		if wpn:isExist() then
			wpn:update()
		else
			-- TODO: we need to do two searches here, one for maximum
			-- effects of ground and air units - to determine if we
			-- trigger an explosion on the unit and or send an
			-- "impact" event to the owning DCT asset.
			--
			-- two, search for all bases within a 4km radius so we can
			-- send "impact" events to these owning DCT airbase assets
			-- to calculate if the impact hit a runway.
			tracked[id] = nil
			local vol = wpn:getEffectsVolume()
			world.searchObjects({
					Object.Category.UNIT,
					Object.Category.STATIC,
				},
				vol, handleobject, wpn)
			vol.params.radius = 5000 -- allows for almost a 15000ft runway
			world.searchObjects(Object.Category.BASE, vol, handlebases, wpn)
		end
	end
	return TRACKED_WEAPON_FREQ
end

local function eventHandler(_, event)
	if not (event.id == world.event.S_EVENT_SHOT and
	   event.weapon and event.initiator) then
		return
	end

	if not isWpnValid(event) then
		Logger:debug("eventHandler - weapon not valid "..
			"typename: "..event.weapon:getTypeName()..
			"initiator: "..event.initiator.getName())
			return
	end
	tracked[event.weapon.id_] = DCTWeapon(event.weapon, event.initiator)
end

local function init(theater)
	assert(theater ~= nil, "value error: theater must be a non-nil value")
	Logger:debug("init weapon tracker system")
	theater:registerHandler(eventHandler, theater)
	theater:queueCommand(TRACKED_WEAPON_FREQ, TrackWeaponsCmd)
end

return init
