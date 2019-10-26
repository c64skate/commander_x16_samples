//
// Skate / Plush
// Oct 2019
//
// Commander X16 320x240x256
// Fullscreen Graphic Example
//

.const Start		= $080d
.const BitmapData	= $0c00

	* = $0801 "Basic"
	BasicUpstart(Start)

	* = Start "Code"
	// copy palette
	lda #$1f
	sta $9f22
	lda #$10
	sta $9f21
	lda #$00
	sta $9f20

	ldy #0
	ldx #0
pal:	lda BitmapPalette,x
	sta $9f23
	inx
	bne pal
	inc pal+2
	iny
	cpy #2
	bne pal

	// init screen

	// scale 2x to have 320x240
	lda #$0f
	sta $9f22
	lda #$00
	sta $9f21
	lda #$01
	sta $9f20
	lda #64
	sta $9f23
	lda #$02
	sta $9f20
	lda #64
	sta $9f23

	// layer 0 configuration
	lda #$20
	sta $9f21
	lda #$00
	sta $9f20
	lda #%11100001
	sta $9f23

	lda #$01	// CTRL1
	sta $9f20
	lda #%00000000
	sta $9f23

	lda #$04	// TILE_BASE_L
	sta $9f20
	lda #%00000000
	sta $9f23

	lda #$05	// TILE_BASE_H
	sta $9f20
	lda #%00000000
	sta $9f23

	// copy bitmap
	lda #$10
	sta $9f22
	lda #$00
	sta $9f20

// load & copy first half
	loadFile(img_p1, img_p1_end-img_p1, BitmapData)

	lda #$00	// $0000 hi-byte
	sta $9f21
	jsr copyBitmap

// load & copy second half
	loadFile(img_p2, img_p2_end-img_p2, BitmapData)

	lda #$64	// $6400 hi-byte
	sta $9f21
	jsr copyBitmap

// load & copy third half
	loadFile(img_p3, img_p3_end-img_p3, BitmapData)

	lda #$c8	// $c800 hi-byte
	sta $9f21
	jsr copyBitmap

	jmp *		// lock

// copy 1/3 of the bitmap area
copyBitmap:
	lda #>BitmapData
	sta bmp+2
	ldy #$00
	ldx #$00
bmp:	lda BitmapData,x
	sta $9f23
	inx
	bne bmp
	inc bmp+2
	iny
	cpy #$64
	bne bmp
	rts

	.encoding "screencode_upper"
img_p1:
	.text "img_p1.bin"
img_p1_end:
img_p2:
	.text "img_p2.bin"
img_p2_end:
img_p3:
	.text "img_p3.bin"
img_p3_end:

BitmapPalette:
// load palette into variable
.var palette = LoadBinary("palette.ACT")

// convert RGB 24 bit palette into X16 palette format
.for(var i = 0; i < palette.getSize(); i+=3) {
	// get r/g/b components
	.var r = palette.get(i) & 255;
	.var g = palette.get(i+1) & 255;
	.var b = palette.get(i+2) & 255;

	// output 2 bytes per RGB value
	.byte (g & $f0) | (b >> 4)
	.byte r >> 4
}

// Macros

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
//        bcs error   // no error handling at the moment
}
