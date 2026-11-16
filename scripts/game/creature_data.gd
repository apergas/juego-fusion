class_name CreatureData extends Resource
## One link of the chain (data/creatures/<id>.tres): its id, name, level, radius in metres,
## colours, look (which features CreatureLooks adds to its ball) and its line of the bestiary.
## Read through Chain; never changed while playing.

@export var id := ""
@export var display_name := ""
@export var level := 1
@export var radius := 0.3
## The main colour: the body (the cap, for the seta) and the particles of its merge.
@export var color := Color.WHITE
## The colour of its features: cheeks, wings, snout, moss, horns, the seta's body.
@export var accent := Color.WHITE
## gota, slime, slime_mejillas, seta, murcielago, lobo, golem or dragon.
@export var look := ""
@export_multiline var lore := ""
