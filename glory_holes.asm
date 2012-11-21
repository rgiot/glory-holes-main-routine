;;
; Intro tentative for RST&8
; Krusty/Benediction
; 4 june 2012
;
; This is a very simple prod with display
; of pictures made with circles
;
; ATTENTION badly assemble with vasm (at least the version of june 2012)

 ifndef __VASM
    ;write "../intro.o"
 endif

START_ADDRESS   equ &4000

BORDER_IN_BLACK equ 0
ENABLE_MUSIC    equ 0
USE_AT_MUSIC    equ 0
ENABLE_INTRO    equ 0
ENABLE_FAST_PLOT equ 0


NB_FRAMES_TO_WAIt_BETWEEN_PICTURES equ 200

SCREEN_WIDTH     equ 80*4
SCREEN_HEIGHT    equ 26*8
MAX_CIRCLE_WIDTH equ 120

GRA_SET_ORIGIN      equ &BBC9
 if ENABLE_FAST_PLOT
GRA_PLOT_ABSOLUTE   equ FPLOT
 else
GRA_PLOT_ABSOLUTE equ &BBEA
 endif
GRA_SET_PEN         equ &BBDE
GRA_RESET           equ &BBBD
SCR_SET_INK         equ &BC32
SCR_SET_BORDER      equ &BC38
SCR_CLEAR           equ &bc14
SCR_SET_MODE        equ &bc0e
TXT_SET_CURSO       equ &BB75   
TXT_OUTPUT          equ &BB5A
TXT_SET_COLUMN      equ &BB6F  
MC_WAIT_FLYBACK     equ  &BD19  

 
 ifdef __VASM
    ;;
    ; Build an entry in the table to encode a circle
    ;
    macro CIRCLE, _X, _Y, _R, _C
        if ENABLE_FAST_PLOT
            dw \_X
            dw \_Y
        else
            dw 2*\_X
            dw 2*\_Y
        endif
        db \_R
        db \_C
    endm
 
    ;;
    ; Build the color entry
    macro COLORS, A, B, C, D
            db \A, \B, \C, \D
    endm


;Fix PSD coordinate
 macro PSD, X,Y,R,C
       CIRCLE \X, (200-\Y),\R,\C
 endm
 else
    ;;
    ; Build an entry in the table to encode a circle
    ;
    macro CIRCLE X, Y, R, C
        if ENABLE_FAST_PLOT
            dw X
            dw 8*25-Y
        else
            dw 2*X
            dw 2*Y
        endif
        db R
        db C
    endm
 
    ;;
    ; Build the color entry
    macro COLORS A, B, C, D
            db A, B, C, D
    endm 



;Fix PSD coordinate
 macro PSD X,Y,R,C
       let YY = 200-Y
       CIRCLE X, YY,R,C
 endm
 endif

    

;;
; Plot the height pixels in one time
; INPUT
;  HL = X
;  DE = Y
 macro PLOT_PIXEL
  ;  di

   
    ; TODO allow to multiply one additional time by two
    ;      in order to simulate shaded circles
    ; x2
    if ENABLE_FAST_PLOT
     ; nothing
    else
        add hl, hl
        ex de, hl
        add hl, hl
    endif



    ; Store values
    ld (VALUE1), de
    ld (VALUE2), hl

    ; 1st pixel
    call GRA_PLOT_ABSOLUTE

    ; 2nd pixel
    ld hl, (VALUE1)
    ld de, (VALUE2)
    call GRA_PLOT_ABSOLUTE

    ; 3rd pixel
    ld bc, (VALUE1)
    ld  hl, 0
    sbc hl, bc
    ld de, (VALUE2)
    call GRA_PLOT_ABSOLUTE
 
    ; 4th pixel
    ld bc, (VALUE1)
    ld  hl, 0
    sbc hl, bc
    ld de, (VALUE2)
    ex de, hl
    call GRA_PLOT_ABSOLUTE

    ; 5th pixel
    ld de, (VALUE1)
    ld bc, (VALUE2)
    ld hl, 0
    sbc hl, bc
    ex de, hl
    call GRA_PLOT_ABSOLUTE

    ; 6th pixel
    ld  de, (VALUE1)
    ld  bc, (VALUE2)
    ld hl, 0
    sbc hl, bc
    call GRA_PLOT_ABSOLUTE

    ;7 th pixel
    ld bc, (VALUE1)
    ld hl, 0
    sbc hl, bc
    ex de, hl
    ld bc, (VALUE2)
    ld hl, 0
    sbc hl, bc
    push hl
    push de
    call GRA_PLOT_ABSOLUTE

    ;8 th pixel
    pop hl
    pop de
    call GRA_PLOT_ABSOLUTE

;    ei
    endm

    if ENABLE_MUSIC
        if USE_AT_MUSIC
            ; do nothing yet
        else
            ifdef __VASM
                ;include data/music_az_vasm/azp.macros.asm
                include data/azp_vasm/azp.macros.asm
            else
                read '..\data\azp_winape\azp.macros.asm'
            endif
        endif
    endif

    org START_ADDRESS


START
    ifndef __VASM
       run $
    endif

    
    if ENABLE_MUSIC
        if USE_AT_MUSIC
            ld de, MUSIC
            call PLAYER
            jp start_point
MUSIC
            incbin data/music_at/LIGHT6.bin
PLAYER
            include data/music_at/ArkosTrackerPlayer_CPC_MSX.asm
        else
            di
            azp_initPeriodTable
        endif
    endif
    
start_point
; {{{ enable bc26table
    if ENABLE_FAST_PLOT
        ld hl, &c000
        ld bc, 512
        ld de, BC26_TABLE
bc26_loop
        ; Store address
        ex de, hl
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
        ex de, hl

        ; compute next line
        push de
        push bc
        call &bc26
        pop bc
        pop de

        dec bc
        ld a, b
        or c
        jr nz, bc26_loop
    endif
; }}}
;; Validation ok sous winape, pas sous vasm ...
    if 0
test
    
      ld b, &f5
vbl
      in a ,(c)
      rra
      jr nc, vbl
      ei
      nop
    halt
    halt
 call firmware_interrupted_code
    halt
        jr test
   endif
 
    ;; Init
    
 
        ld hl,inter_bloc
        ld b,%10000001 ; Priorité 0
        ld c,0
        ld de,firmware_interrupted_code
        call &bcd7 ; KL NEW FRAME FLY



    ;; Intro
    if ENABLE_INTRO
        call intro
    endif

    call &BB84
    ;; Circle pictures effect
    call select_next_picture
effect_loop
    call select_next_circle
    call display_circle
    call GRA_RESET
    jp effect_loop


;;;;;;;;;;; Intro ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
intro

    ; select colors
    ld hl, WRITTER_COLORS
    xor a

    ; ink 0
    ld c, (hl)
    ld b, c
    inc hl
    push hl
    push bc
    push af
    call SCR_SET_INK
    pop af
    pop bc
    pop hl
    push hl
    push bc
    push af
    call SCR_SET_BORDER
    pop af
    pop bc
    pop hl


    ; ink 1
    inc a
    ld c, (hl)
    ld b, c
    inc hl
    push hl
    push bc
    push af
    call SCR_SET_INK
    pop af
    pop bc
    pop hl


    ; ink 2
    inc a
    ld c, (hl)
    ld b, c
    inc hl
    push hl
    push bc
    push af
    call SCR_SET_INK
    pop af
    pop bc
    pop hl

    ; ink 3
    inc a
    ld c, (hl)
    ld b, c
    inc hl
    push hl
    push bc
    push af
    call SCR_SET_INK
    pop af
    pop bc
    pop hl


    ; put cursor at the end
    ld hl, 256 + 27
    call TXT_SET_CURSO
    call intro_print_line
    
    call &BB84 ; TXT_CUR_OFF
    ld b, 160-50
intro_wait   
    call &BD19
    halt
    halt 
    call &BD19
    djnz intro_wait

    ; TODO fondu
    ld a, 1
    call SCR_SET_MODE
    ret

;; Display one line of text
intro_print_line
    ld hl, intro_txt
intro_print_line_loop
    ld a, (hl)
    or a
    ret z
 
    call &BD19  ; MC WAIT FLYBACK
    halt
    halt
    call &BD19  ; MC WAIT FLYBACK

    inc hl

    cp 8
    jr nz, intro_no_backspace
    call TXT_OUTPUT
    ld a, ' '
    call TXT_OUTPUT
    ld a, 8

intro_no_backspace
    call TXT_OUTPUT

intro_cursor 
    ld a, 1
    inc a
    ld (intro_cursor+1), a
    and 1
    jr z, intro_cursor_off
    call &BB81 ; TXT_CUR_ON
    jp intro_print_line_loop
intro_cursor_off
    call &BB84 ; TXT_CUR_OFF
    jp intro_print_line_loop

intro_txt
    db 'WELCOME IN ', &18,'GLORY HOLES',&18, 10, 13
    db 10,13
    db &18,'CrEdIts', &18, ' for the intro winner compo',10,13
    defs 26, 8
    db 'is small intro:', 10,13, 10,13
    db &0f, 2, 'Z80', &0f, 1,  9, 'Krusty/Benediction', 10, 13
    db &0f, 2, 'SFX', &0f, 1, 9, 'Tom&Jerry/Gestation Pour Autrui', 10,13
    defs 25, 8
    db 'PA', 10,13
    db &0f, 2, 'GFX',&0f,1, 9, 'Beb/Vanity', 10,13
    db '   ', 9, 'Ced/Condense', 10,13
    db '   ', 9, 'Grim/Semilanceata', 10,13
    db '   ', 9, 'Voxfreax/Benediction', 10,13

    db 10,13
    db 'Appologies to Loaderror...', 10,13
    db 10,13
    db 'Fuck to the sleeping CPC sceners! '
    defs 34, 8
    db &18,'Kisses to:',&18, &0f, 3
    db ' Arkos'
    db ', ASD'
    db ', Batman Group'
    db ', Br-ainstorm'
    db ', Checkpoint'
    db ', Cosine'
    db ',  Ctrl-Alt-Test'
    db ', Dekadence'
    db ', Dirty Minds'
    db ', Dual Crew&Shining'
    db ', Elude'
    db ', Ephidrena'
    db ', HOOY-PROGRAM'
    db ',MadWizards'
    db ', Matahari' 
    db ', Razor 1911'
    db ', SectorOne'
    db ', Semilanceata'
    db ', tahiti bob cracking  service'
    db ', The Red Sector Inc.'
    db ', Vanity'

    db &0f, 1
    db 10,13
    db 10,13
    db '=> Vote for Us <='
    defs 17,8
    db '                      FIRMWARE RULEZ !!'
    db 10,13
    db 0



    if ENABLE_MUSIC
;;;;;;;;;;;;; MUSIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        if USE_AT_MUSIC
            ;do nothing
        else
            ifdef __VASM
                include data/azp_vasm/reset.data.asm
                include data/azp_vasm/reset.config.asm
                include data/azp_vasm/azp.code.asm
            else
                read '../data/azp_winape/reset.data.asm'
                read '../data/azp_winape/reset.config.asm'
                read '../data/azp_winape/azp.code.asm'
            endif
        endif
    endif

;;;;;;;;;;; Code interruption ;;;;;;;;;;;;;;;;;;
inter_bloc
    defs 10,0

firmware_interrupted_code
    di


    push af
    push bc
 
    push hl
    push de
    exx
    push bc
    push de
    push hl
    ex af, af'
    push af
    push ix
    push iy
    if ENABLE_MUSIC
        if USE_AT_MUSIC
            call PLAYER+3
        else
            call azp_play
        endif
    endif
    pop iy
    pop ix
    pop af
    ex af, af'
    pop hl
    pop de
    pop bc
    exx
    pop de
    pop hl
 
 
leave_inter
     pop bc
     pop af
     ei
     ret


;;;;;;;;;;; Functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;

VALUE1 dw &0000
VALUE2 dw &0000
;;
; Configure system to center axis in the center of circle
; INPUT:
;  HL, DE = center coordinate
;  A = rayon
select_center
    if ENABLE_FAST_PLOT
        ld (XORIGIN), hl
        ld (YORIGIN), de
    else
        push af
        call GRA_SET_ORIGIN
        pop af
    endif
    ret


; Display a circle using Andres Algorithm
;
; INPUT
;  - HL = Y center
;  - DE = X center
display_circle

display_circle_horizontal_position
    ld de, SCREEN_WIDTH
display_circle_vertical_position
    ld hl, SCREEN_HEIGHT
display_circle_radius
    ld a, MAX_CIRCLE_WIDTH

    call select_center

    ld b, a
    ld a, 1
display_circle_loop
    push bc
    push af
    call display_one_circle
    pop af
    pop bc
    inc a
    djnz display_circle_loop
    ret

display_one_circle
    ld d, 0     ; X=0
    ld e, a     ; Y=rayon
    ld c, a
    dec c       ; D=rayon - 1
    ld b, a     ; rayon

    ; D=X, E=Y, B=rayon, C = D
display_one_circle_loop
    ;Tant que y>=x 
    ld a, e
    cp d
    ret c

    ; TracerPixel(x, y) 
    push bc
    push de
    ld l, d
    ld h, 0
    ld d, 0
    ex de, hl

    PLOT_PIXEL

    pop de
    pop bc

test1
    ld a, d
    add a   ; 2x
    cp c    ; d >= 2x ?
    jr nc, test2

    ld l, a ; 2x
    ld a, c ; d
    sub l ; D-2x
    dec a ; D-2x-1
    ld c, a ; D = D-2x-1

    inc d ; X=X+1
    jp display_one_circle_loop

test2
    ld a, b ; rayon
    sub e ; r - y
    add a ; 2(r-y)
    cp c ; d <= 2(r-y)
    jr c, test3 ; d <= 2(r-y) ?

    ld a, e ; y
    add a ; 2y
    add c ; 2y + d
    dec a ; 2y + d - 1
    ld c, a ; d = d+2y-1

    dec e; y=y-1
    jp display_one_circle_loop

test3
    ld a, e
    sub d ; y-x
    dec a ; y-x-1
    add a ; 2(y-x-1)
    add c ; d + 2(y-x-1)
    ld c, a ; d = d + 2(y-x-1)


    inc d ; x=x+1
    dec e  ; y=y-1
    jp display_one_circle_loop



;;
; Select a circle and display it
select_next_circle
    ld hl, NEBULUS

    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl

    ld a, e
    or d
    jp z, circle_finished

    ld (display_circle_horizontal_position+1), de

    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld (display_circle_vertical_position+1), de

    ld a, (hl)
    inc hl
    ld (display_circle_radius+1), a

    ld a, (hl)
    inc hl
    ld (select_next_circle+1), hl
    
    call GRA_SET_PEN
    ret

;;
; Select the next picture to display
circle_finished
    ld b, NB_FRAMES_TO_WAIt_BETWEEN_PICTURES
circle_finished_loop
    push bc
    call MC_WAIT_FLYBACK
    ld b, 0
    djnz $
    pop bc
    djnz circle_finished_loop

    ; TODO clear in a better way
    call clear_screen
    call select_next_picture
    jp effect_loop
    
;;
; Clear the screen using a vertical scroll
clear_screen
    ld hl, 28
    call TXT_SET_CURSO
    ld b, 28
clear_screen_loop
        push bc
        ld a, 10
        call TXT_OUTPUT
        pop bc
        djnz clear_screen_loop

    ld a, 1
    call SCR_SET_MODE
    ret

select_next_picture
    ld hl, PICTURES_SET
select_next_picture_restart
    ; Get address of the picture
    ld e, (hl)
    inc hl
    ld d, (hl)

    ld a, e
    or d
    jr nz, select_next_picture_not_end

    ld hl, PICTURES_SET
    jr select_next_picture_restart
select_next_picture_not_end
    inc hl
    ld (select_next_picture+1), hl



    ; Select the inks
    ex de, hl
    ld b, (hl)
    ld c, b
    push hl
    call SCR_SET_BORDER
    pop hl
  

  if BORDER_IN_BLACK
    push hl
    ld bc, 0
    call SCR_SET_BORDER
    pop hl
  endif

    xor a  
select_next_picture_colors_loop;
;
;    ; Read color number   
    ld b, (hl)
    ld c, b
    inc hl
;
;    ; select color number
    push af
    push hl
    call SCR_SET_INK
    pop hl
    pop af
;
    inc a
    cp 4
    jp nz, select_next_picture_colors_loop;
;
;    ; Store pointer on first circle
    ld (select_next_circle+1), hl

   ; call SCR_CLEAR
    ret


    if ENABLE_FAST_PLOT

BC26_TABLE
  defs 512*2, 0

;cpcwiki programming fast plot
;CMASK  EQU &B338       ;Adress for colormask

XORIGIN dw 0
YORIGIN dw 0                ;664/6128 &B6A3
CMASK equ &B6A3                 

FPLOT  
    ld b, h
    ld c, l
    ld hl,  BC26_TABLE
    add hl, bc
    add hl, bc
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld a, b
    ld (bc), a
    ret
    endif



;;
; Color list of the beginning
WRITTER_COLORS
 db 10, 23, 17, 22

;; List of pictures
PICTURES_SET
    dw BATMAN ; Grim
    dw NEBULUS ; Grim
    dw BEBPICTURE ; Beb
    dw CEDPICTURE ; CED
    dw VOXY ; Voxy
    dw &0000


BATMAN
        DB 0,5,0,0
        PSD 162,102, 81, 1
        PSD 162, 23, 65, 0
        PSD 112,145, 18, 0
        PSD 211,145, 18, 0
        PSD 140,145, 13, 0
        PSD 183,145, 13, 0
        PSD 125,190, 51, 0
        PSD 199,190, 51, 0
        PSD 162, 82, 31, 1
        PSD 187, 64, 18, 0
        PSD 137, 64, 18, 0
        PSD 162, 49, 11, 0
        dw 0

NEBULUS
        db 26,13,0,19
        ; background
        PSD  -3,190, 21, 3
        PSD  37,113, 15, 3
        PSD  54,212, 37, 3
        PSD  41,195, 14, 0
        PSD  68,194, 14, 0
        PSD  39,204, 16, 3
        PSD  15,123,  6, 3
        PSD 254,206, 23, 3
        PSD  44, 92,  6, 3
        PSD 295,136, 10, 3
        PSD  26,154, 25, 3
        PSD  32,141,  8, 0
        PSD  19,145,  5, 0
        PSD  32,166,  6, 0
        PSD 234,114,  4, 3
        PSD  31, 93,  4, 3
        PSD 299,173, 26, 3
        PSD 296,177, 15, 0
        PSD 303,169, 20, 3
        PSD 297,158, 10, 0
        PSD 313,167,  7, 0
        PSD  61, 99,  9, 3
        PSD  79,142, 37, 3
        PSD  82,153, 17, 0
        PSD  74,136, 27, 3
        PSD  82,121, 13, 0
        PSD  63,134, 10, 0
        PSD 242,108,  5, 3
        PSD 287,103, 22, 3
        PSD 286,107, 13, 0
        PSD 283,100, 16, 3
        PSD 283, 92,  8, 0
        PSD 297, 96,  6, 0
        PSD 313,143,  7, 3
        PSD 253,147, 34, 3
        PSD 252,147, 27, 0
        PSD 254,141, 27, 3
        PSD 250,129, 11, 0
        PSD 267,138,  6, 0
        PSD 246,174,  6, 0

        ; foreground
        PSD 107, 63, 32, 1
        PSD 118, 73, 41, 0
        PSD 224, 57, 37, 1
        PSD 213, 69, 45, 0
        PSD 165,131, 66, 2
        PSD 125, 76, 41, 2
        PSD 209, 72, 41, 2
        PSD 164,125, 56, 3
        PSD 162,127, 42, 2
        PSD 149,155, 10, 0
        PSD 167,157, 11, 0
        PSD 165,117, 44, 3
        PSD 153,118,  8, 2
        PSD 173,118,  8, 2
        PSD 128,206, 35, 2
        PSD 202,206, 35, 2
        PSD 128,201, 28, 1
        PSD 123,184, 10, 0
        PSD 201,202, 28, 1
        PSD 200,184, 10, 0
        PSD 124, 73, 32, 0
        PSD 127, 74, 25, 1
        PSD 130, 77, 18, 2
        PSD 207, 72, 36, 0
        PSD 199, 72, 24, 1
        PSD 197, 74, 21, 2
        PSD 139, 68,  9, 0
        PSD 120, 79,  5, 0
        PSD 123, 88,  3, 0
        PSD 208, 66,  9, 0
        PSD 182, 77,  5, 0
        PSD 187, 84,  3, 0
        dw 0

BEBPICTURE
     COLORS 13,0,26,6
    
    CIRCLE 85 , 85,30,1
    CIRCLE 89 , 85, 26,2
    CIRCLE 95, 85 ,20, 1
    CIRCLE 97, 80, 20 ,2

    CIRCLE 160, 100, 80, 1
    CIRCLE 160, 85, 80, 1
    CIRCLE 160, 100 , 75,2
    CIRCLE 160, 85 , 75, 2
    CIRCLE 140 ,40,40,1
    CIRCLE 144, 44,40, 2

    CIRCLE 187,85,20,1
    CIRCLE 187,80,20,2
    CIRCLE 185,75,20,1
    CIRCLE 185,70,20,2
     
    CIRCLE 170,44,28,1
    CIRCLE 150,74,36,2
    
    CIRCLE 178,42,5,2
    CIRCLE 184, 52,4,2
   

    CIRCLE 230,85,30,1
    CIRCLE 224,85,26,2
    CIRCLE 222,85,20,1
    CIRCLE 224,80,20,2
    CIRCLE 220,80,15,1
    CIRCLE 218,78,15,2

    CIRCLE 130,115,20,1
    CIRCLE 130,110,20,2
    CIRCLE 170,125,20,1
    CIRCLE 170,120,20,2
    
    CIRCLE 135,105,10,1
    CIRCLE 135,105,7,0
    CIRCLE 133,105,7,2 
    CIRCLE 130,110,2,1

    CIRCLE 165,105,15,1
    CIRCLE 165,105,12,0
    CIRCLE 163,105,12,2
    CIRCLE 170,100,3,1

    CIRCLE 135,75,20,1
    CIRCLE 138,78,17,2
    CIRCLE 154,68,10,1
    CIRCLE 151,66,8,2


    dw 0






CEDPICTURE
    COLORS 10, 0, 26, 4
    ;CIRCLE POSEx,POSEy,TAILLE,Ink
    ; fond noir
 ;IF 0  ; POUR FAIRE UN SAUT
    ;
    CIRCLE 123,187,4,2 ; BULLE 1 FOND
    CIRCLE 124,172,8,2 ; BULLE 2 FOND
    CIRCLE 130,195,3,2 ; BULLE 3 FOND
    CIRCLE 119,197,2,2 ; BULLE 3 FOND
    ;
    CIRCLE 123,187,3,4 ; BULLE 1 FOND
    CIRCLE 124,172,7,4 ; BULLE 2 FOND
    CIRCLE 130,195,2,4 ; BULLE 3 FOND
    CIRCLE 119,197,1,4 ; BULLE 3 FOND
    ;
    CIRCLE 124,186,3,2
    CIRCLE 125,171,6,2 ; 
    CIRCLE 131,194,2,2 ; 
    CIRCLE 120,196,1,2 ; 
    CIRCLE 215,80,20,1 ; patte 4 fond 
    CIRCLE 230,75,15,1 ; patte 4a fond  
    CIRCLE 240,70,12,1 ; patte 4b fond 
    CIRCLE 245,65,10,1 ; patte 4c fond     
    CIRCLE 250,60,9,1 ; patte 4d fond  
    CIRCLE 257,58,8,1 ; patte 4e fond 
    CIRCLE 260,55,7,1 ; patte 4f fond   
    CIRCLE 262,53,6,1 ; patte 4g fond
    CIRCLE 266,60,5,1 ; patte 4h fond    
    CIRCLE 270,62,4,1 ; patte 4i fond
    ; 
    ;
    CIRCLE 215,80,18,3 ; patte 4 
    CIRCLE 230,75,13,3 ; patte 4a   
    CIRCLE 240,70,11,3 ; patte 4b  
    CIRCLE 245,65,8,3 ; patte 4c     
    CIRCLE 250,60,7,3 ; patte 4d   
    CIRCLE 257,58,6,3 ; patte 4e  
    CIRCLE 260,55,5,3 ; patte 4f    
    CIRCLE 262,53,4,3 ; patte 4g 
    CIRCLE 266,60,3,3 ; patte 4h     
    CIRCLE 270,62,2,3 ; patte 4i 
    ; 
    CIRCLE 165,120,60,1 ; corp fond
    CIRCLE 150,100,50,1 ; corp2 fond
    ;
    CIRCLE 105,80,20,1 ; patte 1 fond
    CIRCLE 100,75,17,1 ; patte 1a fond
    CIRCLE 90,70,15,1 ; patte 1b fond
    CIRCLE 80,68,13,1 ; patte 1c fond
    CIRCLE 70,65,10,1 ; patte 1D fond
    CIRCLE 60,60,8,1 ; patte 1e fond
    CIRCLE 50,60,6,1 ; patte 1f fond
    CIRCLE 45,55,5,1 ; patte 1g fond
    CIRCLE 43,57,4,1 ; patte 1h fond
    CIRCLE 39,58,3,1 ; patte 1i fond
    ;
    CIRCLE 140,60,20,1 ; patte 2 fond
    CIRCLE 135,40,15,1 ; patte 2a fond
    CIRCLE 135,30,12,1 ; patte 2b fond
    CIRCLE 127,18,10,1 ; patte 2c fond
    CIRCLE 120,15,8,1 ; patte 2d fond
    CIRCLE 115,12,7,1 ; patte 2e fond
    CIRCLE 113,8,6,1 ; patte 2f fond
    CIRCLE 112,6,5,1 ; patte 2g fond
    CIRCLE 110,3,4,1 ; patte 2h fond
    CIRCLE 108,2,3,1 ; patte 2i fond
    ;
    CIRCLE 185,55,20,1 ; patte 3 fond
    CIRCLE 188,43,15,1 ; patte 3a fond
    CIRCLE 193,35,12,1 ; patte 3b fond
    CIRCLE 202,28,10,1 ; patte 3c fond
    CIRCLE 210,25,8,1 ; patte 3d fond
    CIRCLE 215,20,7,1 ; patte 3e fond
    CIRCLE 217,18,6,1 ; patte 3f fond
    CIRCLE 220,15,5,1 ; patte 3g fond
    CIRCLE 222,13,4,1 ; patte 3h fond
    CIRCLE 224,11,3,1 ; patte 3i fond
    
    ; remplissage
    ;
    CIRCLE 165,120,58,3 ; corp fond
    CIRCLE 150,100,48,3 ; corp2 fond
    CIRCLE 166,120,55,4 ; corp fond
    CIRCLE 164,118,54,3 ; corp fond
    ;
     ;
    CIRCLE 105,80,18,3 ; patte 1 
    CIRCLE 100,75,15,3 ; patte 1a
    CIRCLE 90,70,13,3 ; patte 1b
    CIRCLE 80,68,11,3 ; patte 1c
    CIRCLE 70,65,8,3 ; patte 1D 
    CIRCLE 60,60,6,3 ; patte 1e
    CIRCLE 50,60,4,3 ; patte 1f 
    CIRCLE 45,55,3,3 ; patte 1g
    CIRCLE 43,57,2,3 ; patte 1h 
    CIRCLE 39,58,1,3 ; patte 1i 
    ;
    CIRCLE 140,60,18,3 ; patte 2 
    CIRCLE 135,40,13,3 ; patte 2a 
    CIRCLE 135,30,9,3 ; patte 2b 
    CIRCLE 127,18,8,3 ; patte 2c 
    CIRCLE 120,15,6,3 ; patte 2d 
    CIRCLE 115,12,5,3 ; patte 2e 
    CIRCLE 113,8,4,3 ; patte 2f 
    CIRCLE 112,6,3,3 ; patte 2g
    CIRCLE 110,3,2,3 ; patte 2h
    CIRCLE 108,2,1,3 ; patte 2i 
    ;
    CIRCLE 185,55,18,3 ; patte 3 
    CIRCLE 188,43,13,3 ; patte 3a 
    CIRCLE 193,35,9,3 ; patte 3b 
    CIRCLE 202,28,8,3 ; patte 3c
    CIRCLE 210,25,6,3 ; patte 3d 
    CIRCLE 215,20,5,3 ; patte 3e 
    CIRCLE 217,18,4,3 ; patte 3f 
    CIRCLE 220,15,3,3 ; patte 3g 
    CIRCLE 222,13,2,3 ; patte 3h 
    CIRCLE 224,11,1,3 ; patte 3i 
    ;
    ;TACHES
    ; tete
    CIRCLE 185,160,10,4 ; TACHE 1  
    CIRCLE 165,150,6,4 ; TACHE 2 
    CIRCLE 192,145,3,4 ; TACHE 3 
    ;
    ; patte 1
    CIRCLE 190,80,8,4 ; TACHE 1 
    CIRCLE 173,75,5,4 ; TACHE 2 
    CIRCLE 180,68,3,4 ; TACHE 3 
    ; patte 2
    CIRCLE 105,80,2,4 ; TACHE 1 
    CIRCLE 98,76,3,4 ; TACHE 2 
    CIRCLE 100,66,5,4 ; TACHE 3 
    

    ;
    ;SOURCILS
    CIRCLE 120,115,20,1 ;  1 FOND 
    CIRCLE 154,113,15,1 ;  2 FOND 
    CIRCLE 120,115,18,3 ;  3 FOND 
    CIRCLE 154,113,13,3 ;  4 FOND 
    
    ;YEUX
    ;
    CIRCLE 120,110,20,1 ; OEIL 1 FOND 
    CIRCLE 154,108,15,1 ; OEIL 2 FOND 
    ;
    CIRCLE 120,110,18,2 ; OEIL 1  
    CIRCLE 154,108,13,2 ; OEIL 2 
    ;
    CIRCLE 125,110,9,1 ; IRIS 1  
    CIRCLE 150,108,5,1 ; IRIS 2 
    ;
    CIRCLE 125,110,3,2 ; IRIS 1  
    CIRCLE 150,108,2,2 ; IRIS 2
    ;
    ;BOUCHE
    CIRCLE 120,80,13,1 ; BOUCHE 1
    CIRCLE 120,80,11,3 ; BOUCHE 2
    CIRCLE 120,78,8,1 ; BOUCHE 3
    CIRCLE 120,79,7,3 ; BOUCHE 4
    CIRCLE 120,78,6,1 ; BOUCHE 5
    ; bulles
    CIRCLE 133,31,3,2 ; BULLE 1 
    CIRCLE 114,26,6,2 ; BULLE 2 
    CIRCLE 130,23,4,2 ; BULLE 3 
    CIRCLE 129,9,7,2 ; BULLE 4 
    ;
    CIRCLE 133,31,2,4 ; BULLE 1 
    CIRCLE 114,26,5,4 ; BULLE 2 
    CIRCLE 130,23,3,4 ; BULLE 3 
    CIRCLE 129,9,6,4 ; BULLE 4 
    ;
    CIRCLE 134,30,2,2
    CIRCLE 115,25,4,2 ; 
    CIRCLE 131,22,2,2 ; 
    CIRCLE 130,8,5,2 ; 
    ;
    CIRCLE 263,65,5,2 ; BULLE 4
    CIRCLE 244,60,6,2 ; BULLE 6 
    CIRCLE 260,75,2,2 ; BULLE 7 
    CIRCLE 259,52,4,2 ; BULLE 8 
    ;
    CIRCLE 263,65,4,4 ; BULLE 4
    CIRCLE 244,60,5,4 ; BULLE 6 
    CIRCLE 260,75,1,4 ; BULLE 7 
    CIRCLE 259,52,3,4 ; BULLE 8 
    ;
    CIRCLE 264,63,4,2 ; BULLE 4
    CIRCLE 245,58,5,2 ; BULLE 6 
    CIRCLE 261,74,1,2 ; BULLE 7 
    CIRCLE 260,51,3,2 ; BULLE 8 

 ;ENDIF

;  if 0
    ;
    ;ALGUES
    ;
    CIRCLE 12,2,10,3 ; algue 1
    CIRCLE 13,9,7,3
    CIRCLE 13,15,9,3
    CIRCLE 13,20,7,3
    CIRCLE 14,24,3,3
    CIRCLE 14,27,4,3
    CIRCLE 12,32,6,3
    CIRCLE 13,37,8,3
    CIRCLE 15,41,8,3
    CIRCLE 12,46,5,3
    CIRCLE 12,46,5,3
    CIRCLE 14,52,3,3
    CIRCLE 13,55,4,3
    CIRCLE 15,58,5,3
    CIRCLE 14,60,2,3
    CIRCLE 12,63,5,3
    CIRCLE 14,70,3,3
    CIRCLE 17,75,6,3
    CIRCLE 15,80,9,3
    CIRCLE 14,85,7,3
    CIRCLE 12,90,6,3
    CIRCLE 13,95,8,3
    CIRCLE 15,100,8,3
    CIRCLE 12,110,5,3
    CIRCLE 12,120,7,3
    CIRCLE 14,130,6,3
    CIRCLE 13,140,9,3
    CIRCLE 15,150,6,3
    CIRCLE 14,160,4,3
    CIRCLE 12,165,5,3
    CIRCLE 17,58,5,3
    CIRCLE 19,60,4,3
    CIRCLE 11,62,8,3
    CIRCLE 13,64,5,3
    CIRCLE 15,66,7,3
    CIRCLE 17,68,4,3
    CIRCLE 19,71,5,3
    CIRCLE 22,75,3,3
    CIRCLE 24,78,4,3
    CIRCLE 26,80,5,3
    CIRCLE 28,82,3,3
    CIRCLE 28,84,2,3
    CIRCLE 27,86,4,3
    CIRCLE 26,88,3,3
    CIRCLE 28,90,6,3
 ;
    CIRCLE 302,2,10,3 ; algue 1
    CIRCLE 302,9,7,3
    CIRCLE 302,15,9,3
    CIRCLE 302,20,7,3
    CIRCLE 304,24,3,3
    CIRCLE 304,27,4,3
    CIRCLE 302,32,6,3
    CIRCLE 303,37,8,3
    CIRCLE 305,41,8,3
    CIRCLE 302,46,5,3
    CIRCLE 302,46,5,3
    CIRCLE 304,52,3,3
    CIRCLE 303,55,4,3
    CIRCLE 305,58,5,3
    CIRCLE 304,60,2,3
    CIRCLE 302,63,5,3
    CIRCLE 304,70,3,3
    CIRCLE 307,75,6,3
    CIRCLE 305,80,9,3
    CIRCLE 304,85,7,3
    CIRCLE 302,90,6,3
    CIRCLE 303,95,8,3
    CIRCLE 305,100,8,3
    CIRCLE 302,110,5,3
    CIRCLE 302,120,7,3
    CIRCLE 304,130,6,3
    CIRCLE 303,140,9,3
    CIRCLE 305,150,6,3
    CIRCLE 304,160,4,3
    CIRCLE 302,165,5,3
    CIRCLE 307,170,4,3
    CIRCLE 309,175,3,3
    CIRCLE 311,180,4,3
    CIRCLE 313,185,2,3
    CIRCLE 290,66,7,3
    CIRCLE 297,67,4,3
    CIRCLE 299,68,8,3
    CIRCLE 292,69,3,3
    CIRCLE 290,70,4,3
    CIRCLE 292,71,7,3
    CIRCLE 298,72,3,3
    CIRCLE 297,74,2,3
    CIRCLE 297,76,4,3
    CIRCLE 296,78,3,3
    CIRCLE 295,80,6,3

; endif


    

    
    
    dw 0



VOXY
    
    COLORS 13, 0, 23, 14         ; Inks to use


    ; moon
    PSD 47,48,44, 3
    PSD 61,31,31,0

    ;grass
    PSD 10,191,19,2
    PSD 30,198,12,2
    PSD 312,194,12,2
    PSD 293,190,13,2
    PSD 271,199,15,2

    ;cloud 1
    PSD 145,25,17,2
    PSD 127,20,8,2 
    PSD 132,37,12,2
    PSD 114,30,11,2
    PSD 147,22,10,3
    PSD 131,40,6,3
    PSD 133,38,7,2
    PSD 145,23,9,2

    ;cloud 2
    PSD 202,13,10,2
    PSD 215,13,8,2
    PSD 215,11,4,3
    PSD 202,24,6,2
    PSD 213,15,6,2
    PSD 213,25,8,2

    ;cloud3
    PSD 214,49,9,2
    PSD 204,56,10,2
    PSD 213,62,13,2
    PSD 225,59,11,2
    PSD 201,55,6,3
    PSD 203,55,6,2
    PSD 229,60,6,3
    PSD 227,60,6,2

    ;cloud4
    PSD  264,23,10,2
    PSD  270,37,12,2
    PSD  282,29,17,2
    PSD  287,43,13,2
    PSD  283,26,10,3
    PSD  279,29,12,2

    ;foot black
    PSD 123,200,19,1
    PSD 176,200,31,1
    PSD 176,198,26,2
    PSD 123,200,16,2

    ;left ear
    PSD 102,98,12,1
    PSD 103,99,10,2
    PSD 104,100,6,1

    ;right ear
    PSD 138,97,12,1
    PSD 139,98,10,2
    PSD 140,99,6,1      
  
    ;body
    PSD 138,159,36,1
    PSD 137,159,34,3

    ;left arm
    PSD 91,162,13,1
    PSD 92,163,11,2

    ;right arm
    PSD 170,129,13,1
    PSD 168,130,11,3
    PSD 171,127,11,3
    PSD 180,121,13,1
    PSD 181,122,11,2

    ;head
    PSD 123,128,32,1
    PSD 123,128,30,3
    PSD 123,128,25,1 

    ;head
    PSD 123,123,24,3
 
   ;left eye
    PSD 111,112,6,1
    PSD 110,113,5,3
    PSD 112,114,4,1
    PSD 112,114,4,1
    PSD 112,114,3,2

    ;right eye
    PSD 137,112,6,1
    PSD 138,113,5,3
    PSD 136,114,4,1
    PSD 136,114,3,2

    ;left finger
     PSD 86,164,6,1
     PSD 96,158,4,1
     PSD 86,164,5,0
     PSD 96,158,3,0

    ;right finger
    PSD 175,124,4,1
    PSD 183,116,6,1
    PSD 175,124,3,0
    PSD 183,116,5,0

    ;nose
    PSD 120,120,1,1
    PSD 128,120,1,1
    dw 0
