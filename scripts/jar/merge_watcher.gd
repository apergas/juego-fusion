class_name MergeWatcher extends Node
## Node, a piece of Jar: finds two creatures of the same level touching. Every physics frame
## (step(), called by Jar) it asks each creature for the bodies it touches (its contact monitor)
## and pairs it with the first equal one still free; both are marked merged at once, so a
## creature merges only once per contact: of three equal ones touching, two merge and the third
## waits for its next contact. It only reports (touched); Game decides what the pair gives.

signal touched(a: CreatureBody, b: CreatureBody)


func step(bodies: Array[CreatureBody]) -> void:
	var pairs: Array[Array] = []
	for body in bodies:
		if body.merged:
			continue
		for other in body.get_colliding_bodies():
			var mate := other as CreatureBody
			if mate == null or mate.merged or mate.data.level != body.data.level:
				continue
			body.merged = true
			mate.merged = true
			pairs.append([body, mate])
			break
	# After the loop: a merge changes the list of bodies.
	for pair in pairs:
		touched.emit(pair[0], pair[1])
