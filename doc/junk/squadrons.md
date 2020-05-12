# Squadrons

A logical representation of a group of aircraft associated with a given
airbase.

## Attributes

 * airframe type
 * number available
 * homebase
 * combat radius
 * payloads
 * taskings the squadron is capable of
 * supply (the amount of resources the squadron has available)
 * resupply rate in seconds

## Squadron Death

 * only on the distruction of their airbase

## Not Able to Field Flights

 * airframe count depleted
 * runway disabled
 * airbase captured

problem:
- be able to define CAP corradors
- have an EWR/GCI network that feeds information to the CAP flights

example
- 5 sqdns
- define an airspace that each sqdn defends


CAP flight lead goals:
- investigate
   - 
- intercept
   - 
- attack
   - commit criteria
- persue
- disengage
- refuel
- rtb
- race-track on-station hold

actions setup per flight
- set reaction to threat
- use flare
- use ecm


flight lead actions:
- use radar
- set freq
- set ROE
- prohibit ab
- land
- takeoff


CAP flight lead actions:
- goto waypoint
- race-track hold (idle state until fuel low)
- refuel
- engageTargets
- missile attack range


flight lead attributes monitored:
- fuel state
- Friendly and Enemy SAM threat
- Friendly & enemy airbourne threats
- damage taken
- mission specific
  - cap station orbit size
  - ground targets


flight lead personalities:
- aggressiness
- emission awareness
- positioning (altitude & aspect)
- dcs skill level


squadron:
- skill range of pilot
- define airframe
- number of airframes available
- define airfield operating out of
- weapons loadouts; interceptor a/c vs. CAP a/c
- squadrons should be able to scramble a certian amount of jets
- allow designer to define the maintaince rate for given states of a/c returning


air defense commander:
- morphable border, determined by presence of ground assets in a given area
- select automatically CAP stations based on priority and threat
- assign sqdns to CAP stations based on distance
- be able to scramble alerts a/c
- critera for scrambling alert a/c 
   * alerts are only used when all airborne CAP car committed
   * alert a/c RTB once a threat has been dewlt with