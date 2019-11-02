//
// Skate / Plush
// Nov 2019
//
// Commander X16 640x480x256
// Fullscreen Water Renderding Demo
//

// library includes
#import "65c02_opcodes.asm"
#import "file_manager.asm"

// memory addresses
.const Basic		= $0801
.const CodeStart	= $080d
.const TempBitmapData	= $1000
.const FPPDataLo	= $1000
.const FPPDataHi	= $5600

// zp addresses
.const rasterPointer	= $10
.const irqPointer	= $12
.const loFPPPointer	= $14
.const hiFPPPointer	= $16
.const lineCounter	= $18

// definitions
.const screenHeight = 480
.const imageHeight = 200
.const emptyAreaHeight = screenHeight - imageHeight
.const numberOfWaveFrames = 64

	* = Basic "Basic"
	BasicUpstart(CodeStart)

	* = CodeStart "Code"
	// set VERA control bits to select data port #0 (already default value)
	lda #%00000000
	sta $9f25

	// store default kernal irq call address
	lda $0314
	sta irqPointer
	lda $0315
	sta irqPointer+1

	// copy palette
	lda #$1f
	sta $9f22
	lda #$10
	sta $9f21
	stz $9f20
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

	// layer 0 configuration
	lda #$20
	sta $9f21
	stz $9f20	// CTRL0
	lda #%11100001
	sta $9f23

	lda #$01	// CTRL1
	sta $9f20
	lda #%00010000
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
	stz $9f20

	// load & copy first part
	loadFile(img_p1, img_p1_end-img_p1, TempBitmapData)

	stz $9f21 // first part will be loaded to $0:0000

	jsr copyBitmap

	// load & copy second part
	loadFile(img_p2, img_p2_end-img_p2, TempBitmapData)

	lda #>(1*$6400&$ffff)
	sta $9f21

	jsr copyBitmap

	// load & copy third part
	loadFile(img_p3, img_p3_end-img_p3, TempBitmapData)

	lda #>(2*$6400&$ffff)
	sta $9f21

	jsr copyBitmap

	lda #$11 // next part will overflow 64k area so set the 9th address bit
	sta $9f22
	// load & copy forth part
	loadFile(img_p4, img_p4_end-img_p4, TempBitmapData)

	lda #>(3*$6400&$ffff)
	sta $9f21

	jsr copyBitmap

	// load & copy fifth part
	loadFile(img_p5, img_p5_end-img_p5, TempBitmapData)

	lda #>(4*$6400&$ffff)
	sta $9f21

	jsr copyBitmap

	// load fpp datas
	loadFile(d_lo, d_lo_end-d_lo, FPPDataLo)
	loadFile(d_hi, d_hi_end-d_hi, FPPDataHi)

	// reset fpp table pointers
	lda #<FPPDataLo
	sta loFPPPointer
	lda #>FPPDataLo
	sta loFPPPointer+1
	lda #<FPPDataHi
	sta hiFPPPointer
	lda #>FPPDataHi
	sta hiFPPPointer+1

	// set interrupt
	sei
	lda #<irq01
	sta $0314
	lda #>irq01
	sta $0315
	cli

	// lock outside of the irq
	jmp *

	// first irq routine
	// this is the beginning of the screen
	// we reset some VERA registers to display
	// graphic screen regularly at the first
	// 200 raster lines
irq01:
	lda #$0f
	sta $9f22
	stz $9f21

	lda #$08	// DC_STARTSTOP_H
	sta $9f20
	lda #%11101000
	sta $9f23

	lda #$06	// DC_VSTART_L
	sta $9f20
	stz $9f23

	// set second irq as the next irq
	lda #<irq02
	sta $0314
	lda #>irq02
	sta $0315

	// set raster position and pointer values
	lda #$0a	// DC_IRQ_LINE_H
	sta $9f20
	stz $9f23
	stz rasterPointer+1

	lda #$09	// DC_IRQ_LINE_L
	sta $9f20
	ldx #imageHeight	// trigger next irq at the end of the image data
	stx $9f23
	inx
	stx rasterPointer

	// reset line counter
	stz lineCounter
	stz lineCounter+1

	// go to kernal default irq ending
	jmp (irqPointer)

	// second irq routine
	// this is where the fpp magic happens (water rendering)
irq02:
	lda #$0f
	sta $9f22
	stz $9f21

	// add pointers to line counter and calculate
	// FPP look up table addresses
	lda lineCounter
	clc
	adc loFPPPointer
	sta ll+1
	sta lh+1

	lda lineCounter+1
	adc loFPPPointer+1
	sta ll+2
	adc #>(FPPDataHi-FPPDataLo)
	sta lh+2

	// FPP routine
	lda #$06	// DC_VSTART_L
	sta $9f20

ll:	lda $ffff
	sta $9f23

	lda #$08	// DC_STARTSTOP_H
	sta $9f20

lh:	lda $ffff
	sta $9f23

	// increase line counter
	inc lineCounter
	bne !+
	inc lineCounter+1
!:
	// set raster position
	lda #$09	// DC_IRQ_LINE_L
	sta $9f20
	lda rasterPointer
	sta $9f23

	lda #$0a	// DC_IRQ_LINE_H
	sta $9f20
	lda rasterPointer+1
	sta $9f23

	// increase raster pointer
	inc rasterPointer
	bne !+
	inc rasterPointer+1
!:	
	lda rasterPointer+1
	cmp #$01
	bne !exitirq+
	lda rasterPointer
	cmp #$e1 // continue if end of screen is reached (480 = $1e0 +1)
	bne !exitirq+	

	// end of screen reached

	// reset raster pointer
	stz rasterPointer
	stz rasterPointer+1

	// increase low fpp table address pointer by empty area height
	lda loFPPPointer
	clc
	adc #<emptyAreaHeight
	sta loFPPPointer
	lda loFPPPointer+1
	adc #>emptyAreaHeight
	sta loFPPPointer+1
	cmp #>(FPPDataLo+emptyAreaHeight*numberOfWaveFrames) // is it the last frame?
	bne !cont+

	// reset fpp table pointers
	lda #<FPPDataLo
	sta loFPPPointer
	lda #>FPPDataLo
	sta loFPPPointer+1
	lda #<FPPDataHi
	sta hiFPPPointer
	lda #>FPPDataHi
	sta hiFPPPointer+1

	jmp !out+
!cont:
	// increase high fpp table address pointer by empty area height
	lda hiFPPPointer
	clc
	adc #<emptyAreaHeight
	sta hiFPPPointer
	lda hiFPPPointer+1
	adc #>emptyAreaHeight
	sta hiFPPPointer+1
!out:
	// enable line + vblank
	lda #%00000011
	sta $9f26

	// set first irq as the next irq
	lda #<irq01
	sta $0314
	lda #>irq01
	sta $0315

	// go to kernal default irq ending
	jmp (irqPointer)

!exitirq:
	// trigger next line irq
	lda #%00000010
	sta $9f26
	sta $9f27

	// exit irq
	ply
	plx
	pla
	rti

// copy $6400 number of bitmap bytes to VERA's memory
copyBitmap:
	lda #>TempBitmapData
	sta bmp+2
	ldy #$00
	ldx #$00
bmp:	lda TempBitmapData,x
	sta $9f23
	inx
	bne bmp
	inc bmp+2
	iny
	cpy #>$6400
	bne bmp
	rts

	// file names to load
	.encoding "screencode_upper"
img_p1:
	.text "image_p1.bin"
img_p1_end:
img_p2:
	.text "image_p2.bin"
img_p2_end:
img_p3:
	.text "image_p3.bin"
img_p3_end:
img_p4:
	.text "image_p4.bin"
img_p4_end:
img_p5:
	.text "image_p5.bin"
img_p5_end:
d_lo:
	.text "data_lo.bin"
d_lo_end:
d_hi:
	.text "data_hi.bin"
d_hi_end:

	// bitmap color palette data
BitmapPalette:
// load palette into variable
.var palette = LoadBinary("image.ACT")

// convert RGB 24 bit palette into X16 palette format
.for(var i = 0; i < palette.getSize(); i+=3) {
	.var r = palette.get(i) & 255;
	.var g = palette.get(i+1) & 255;
	.var b = palette.get(i+2) & 255;

	.byte (g & $f0) | (b >> 4)
	.byte r >> 4
}
