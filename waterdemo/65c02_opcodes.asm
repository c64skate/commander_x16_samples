// stz $xxxx
.pseudocommand stz address {
	.byte $9c
	.byte <address.getValue()
	.byte >address.getValue()
}

// phx
.pseudocommand phx {
	.byte $da
}

// phy
.pseudocommand phy {
	.byte $5a
}

// plx
.pseudocommand plx {
	.byte $fa
}

// ply
.pseudocommand ply {
	.byte $7a
}
