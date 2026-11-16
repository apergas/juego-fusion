class_name Profile extends RefCounted
## What the player keeps from round to round, saved with the options (SaveData): the best score
## ever and the creatures discovered (ids of Chain.IDS, in the order they were found). Pure: no
## nodes. Scoring and Bestiary change it.

var best_score := 0
var discovered: Array[String] = []
