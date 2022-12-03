extends "PhaseDiagram.gd"

func _ready():
	place(194, 1, $MeltPoint)
	place(216, 5.18, $TriplePoint)
	place(304, 73.8, $SuperPoint)

var colors = {	"S":Color(0.66, 0.66, 0.66, 0.7),
				"L":Color(0.66, 0.66, 0.66, 1.0),
				"SC":Color(0.66, 0.66, 0.66, 0.4)}
