  ;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
  .equ STACK, 0x2000 				; start of stack memory
  .equ LEDS, 0x2000                 ; LED address
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ BUTTONS, 0x2030              ; Buttons addresses

  ;; type enumeration
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04

  ;; GSA type
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

  ;; orientation enumeration
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4

  ;; collision boundaries
  .equ COL_X, 4
  .equ COL_Y, 3

  ;; Rotation enumeration
  .equ CLOCKWISE, 0
  .equ COUNTERCLOCKWISE, 1

  ;; Button enumeration
  .equ moveL, 0x01
  .equ rotL, 0x02
  .equ reset, 0x04
  .equ rotR, 0x08
  .equ moveR, 0x10
  .equ moveD, 0x20

  ;; Collision return ENUM
  .equ W_COL, 0
  .equ E_COL, 1
  .equ So_COL, 2
  .equ OVERLAP, 3
  .equ NONE, 4

  ;; start location
  .equ START_X, 6
  .equ START_Y, 1

  ;; game rate of tetrominoe falling down (in terms of game loop iteration)
  .equ RATE, 5

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8


# CODE IS HERE
main_for_testing_code: 
	addi t0, zero, 0
	addi t1, zero, 0
	bne t0, t1, start_drawing
	call set_up_will_be_deleted
	start_drawing:
		call draw_gsa
break

; BEGIN:clear_leds
clear_leds:
	addi t0, zero, 4
	addi t1, zero, 8
	stw zero, LEDS(zero) # store zero into first leds
	stw zero, LEDS(t0)	 # store zero into second leds
	stw zero, LEDS(t1)	 # store zero into thirds leds
	ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	ldw t0, LEDS(a0)	# load correct leds
	addi t1, zero, 1	
	andi t2, a0, 3		# isolate 2 lsb of x coordinate
	slli t2, t2, 3		# move to correct column
	add t2, t2, a1		# move to correct row
	sll t1, t1, t2		# shift mask to correct position
	or t1, t0, t1		
	stw t1, LEDS(a0)	# store new value in leds
	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi t0, zero, 0 # index to increment
	addi t1, zero, 1 
	slli t1, t1, 20	 # ceil value
	loop_wait:
		addi t0, t0, 1
	bne t0, t1, loop_wait
	ret
; END:wait

; BEGIN:in_gsa
in_gsa:
	cmpgei t0, a0, 12
	cmplti t1, a0, 0
	or t2, t0, t1	  # x is in gsa
	cmpgei t0, a1, 8
	cmplti t1, a1, 0
	or t1, t0, t1 	  # y is in gsa
	or v0, t1, t2     # both x, y are in gsa
	ret
; END:in_gsa

; BEGIN:get_gsa
get_gsa:
	slli t0, a0, 3
	add t0, t0, a1
	slli t0, t0, 2	# gsa address
	ldw v0, GSA(t0)	# load value of address
	ret
; END:get_gsa
	
; BEGIN:set_gsa
set_gsa:
	slli t0, a0, 3
	add t0, t0, a1
	slli t0, t0, 2	# gsa address 
	stw a2, GSA(t0) # store p state in gsa
	ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -4	 # push stack pointer
	stw ra, STACK(sp) # save ra to stack
	call clear_leds
	addi t0, zero, 0 # x coordinate value
	addi t1, zero, 0 # y coordinate value
	loop_draw_gsa:
		add a0, zero, t0 # retrieve x coordinate
		add a1, zero, t1 # retrieve y coordinate
		call push_stack
		call get_gsa
		call pop_stack
		addi t2, zero, NOTHING # nothing p value
		beq v0, t2, increment_coordinates # skip set pixel if nothing 
		call push_stack
		call set_pixel # leds coordinates are already in registers a0 (x) and a1 (y)
		call pop_stack
		increment_coordinates:
			addi t2, zero, 7  # value when y coordinate reset
			bne t1, t2, increment_y_coord # if y != 7 branch increment_y_coord
			increment_x_coord:
				addi t0, t0, 1   # increment x
				addi t1, zero, 0 # reset y to 0
				br last_procedure 
			increment_y_coord:
				addi t1, t1, 1  # increment y
			last_procedure:
				add a0, zero, t0 # new value of x 
				add a1, zero, t1 # new value of y
				call push_stack
				call in_gsa # check if new values (x,y) are in gsa
				call pop_stack
	addi t2, zero, 1 # value when (x,y) are not in gsa
	bne t2, v0, loop_draw_gsa # branch if new coordinates are in gsa
	ldw ra, STACK(sp) # load ra from stack
	addi sp, sp, 4	  # pop stack pointer
	ret
; END:draw_gsa

; BEGIN:draw_tetromino
draw_tetromino:
	ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
	ret
; END:generate_tetromino

; BEGIN:helper
push_stack:		
	addi sp, sp, -4
	stw t0, STACK(sp)
	addi sp, sp, -4
	stw t1, STACK(sp)
	ret

pop_stack:
	ldw t1, STACK(sp)
	addi sp, sp, 4
	ldw t0, STACK(sp)
	addi sp, sp, 4
	ret

set_up_will_be_deleted:
		addi sp, sp, -4
		stw ra, STACK(sp)	
		addi a0, zero, 0xB
		addi a1, zero, 0
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 1
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 2
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 3
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 4
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 5
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 6
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xB
		addi a1, zero, 7
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 2
		addi a1, zero, 0
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 2
		addi a1, zero, 1
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 6
		addi a1, zero, 2
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 1
		addi a1, zero, 3
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 7
		addi a1, zero, 4
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xA
		addi a1, zero, 5
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 8
		addi a1, zero, 6
		addi a2, zero, FALLING
		call set_gsa
		addi a0, zero, 0xA
		addi a1, zero, 7
		addi a2, zero, FALLING
		call set_gsa
		ldw ra, STACK(sp)
		addi sp, sp, 4
		ret
; END:helper

font_data:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y