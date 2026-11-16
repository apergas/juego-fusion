class_name Profile extends RefCounted
## What the player keeps from round to round, saved with the options (SaveData): the best score
## ever, the creatures discovered (ids of Chain.IDS, in the order they were found) and the round
## in progress the player left. Pure: no nodes. Scoring and Bestiary change it.

var best_score := 0
var discovered: Array[String] = []

## The round the player left still going (RoundSnapshot), {} for none: the title's Seguir.
var saved_round := {}
