class_name Bestiary extends RefCounted
## Which creatures the player has seen. Pure: works on the Profile. A creature is discovered the
## first time it is in the jar, dropped or made by a merge, in silence: nothing in the round says
## so, only the bestiary shows it. The bestiary shows UNKNOWN for the ones not yet discovered.

const UNKNOWN := "???"


## True (and the profile changed) if id had not been discovered.
static func discover(profile: Profile, id: String) -> bool:
	if profile.discovered.has(id):
		return false
	profile.discovered.append(id)
	return true


static func is_discovered(profile: Profile, id: String) -> bool:
	return profile.discovered.has(id)
