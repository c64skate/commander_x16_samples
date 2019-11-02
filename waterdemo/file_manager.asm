//
// loadFile
// Loads file from device #1
// This routine will skip first two bytes of the file
// and loads the file to given address. So, first two
// bytes can be random bytes.
// 
// params:
// filename: memory pointer of the filename
// filenameLength: length of the filename
// address: load address 
//
.macro loadFile(filename, filenameLength, address) {
        lda #filenameLength
        ldx #<filename
        ldy #>filename
        jsr $ffbd     // SETNAM
        lda #$01
        ldx #$01      // device number
	ldy #$00      // load new address
        jsr $ffba     // SETLFS

        ldx #<address
        ldy #>address
        lda #$00      // load -> memory
        jsr $ffd5     // LOAD
//        bcs error
}
