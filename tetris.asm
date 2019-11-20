  ;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
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
  .equ RATE, 1

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8


# CODE IS HERE 

init_stack_pointer:
	addi sp, zero, 0x2000

main2:
	call reset_game
m_generate_tetromino_loop:
m_falling_loop:
	addi s0, zero, RATE
m_input_loop:
	beq s0, zero, m_input_loop_end
	call draw_gsa
	call display_score
	addi a0, zero, NOTHING
	call draw_tetromino
	call wait
	call get_input
	addi a0, v0, 0
	beq a0, zero, skip_no_input
	call act
skip_no_input:
	addi a0, zero, FALLING
	call draw_tetromino
	addi s0, s0, -1
	jmpi m_input_loop
m_input_loop_end:
	addi a0, zero, NOTHING
	call draw_tetromino
	addi a0, zero, moveD
	call act
	bne v0, zero, m_falling_loop_end
	addi a0, zero, FALLING
	call draw_tetromino
	jmpi m_falling_loop
m_falling_loop_end:
	addi a0, zero, PLACED
	call draw_tetromino
m_remove_full_lines_loop:
	call detect_full_line
	addi t0, zero, 8
	beq v0, t0, m_remove_full_lines_loop
	addi a0, v0, 0
	call remove_full_line
	call increment_score
	jmpi m_remove_full_lines_loop
m_remove_full_lines_end:
	call generate_tetromino
	addi a0, zero, OVERLAP
	add s1, zero, a0
	call detect_collision
	beq s1, v0, m_generate_tetromino_loop_end
	addi a0, zero, FALLING
	call draw_tetromino
	jmpi m_generate_tetromino_loop
m_generate_tetromino_loop_end:
	jmpi main

break
; BEGIN:main
main:
	addi s0, zero, RATE
	call reset_game
	playing_game:
	falling_tetromino:
		add s1, zero, zero
		
		inner_loop:
		beq s0, s1, skip2
		call draw_gsa
		call display_score
		addi a0, zero, NOTHING
		call draw_tetromino
		call wait
		call get_input
		add a0, zero, v0
		beq a0, zero, skip
		call act
		call draw_tetromino
		skip:
		addi s1, s1, 1
		br inner_loop
		
		skip2:
		addi a0, zero, NOTHING
		call draw_tetromino
		addi a0, zero, moveD
		call act
		add s2, zero, v0
		call draw_tetromino
		
	bne s2, zero, falling_tetromino
	
	addi a0, zero, PLACED	
	call draw_tetromino
	
	remove_full_lines:
		call detect_full_line
		addi t0, zero, 8
		beq v0, t0, generate_new
		call remove_full_line
		br remove_full_lines
	
	generate_new:
		call generate_tetromino
		addi a0, zero, OVERLAP	
		call detect_collision
		addi t0, zero, OVERLAP
		beq v0, t0, end_game
		call draw_tetromino
		br playing_game
	end_game:
	ret
; END:main
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
	slli t1, t1, 1	 # ceil value (20)
	loop_wait:
		addi t0, t0, 1
	bne t0, t1, loop_wait
	ret
; END:wait

; BEGIN:in_gsa
in_gsa:
	cmpgei t0, a0, X_LIMIT
	cmplti t1, a0, 0
	or t2, t0, t1	  # x is in gsa
	cmpgei t0, a1, Y_LIMIT
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
	stw ra, 0(sp) # save ra to stack
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
			addi t2, zero, Y_LIMIT-1  # y index just before being reset to 0
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
	ldw ra, 0(sp) # load ra from stack
	addi sp, sp, 4	  # pop stack pointer
	ret
; END:draw_gsa

; BEGIN:draw_tetromino
draw_tetromino:
	addi sp, sp, -4
	stw ra, 0(sp)
	# save in registers details about the falling tetromino
	add t0, a0, zero
	ldw t1, T_X(zero)
	ldw t2, T_Y(zero)
	ldw t3, T_orientation(zero)
	ldw t4, T_type(zero)
	# set arguments to set_gsa
	add a0, zero, t1 
	add a1, zero, t2
	add a2, zero, t0 
	call push_stack
	call set_gsa # set the anchor of tetromino
	call pop_stack
	addi t7, zero, 0 # initialize counter
	slli t5, t4, 2   # *4 to select appropriate location in DRAW_Ax
	add t5, t5, t3   # incremented by orientation for the triplet
	slli t5, t5, 2   # *4 again
	draw_3_squares_loop: # set the 3 other points
		ldw t6, DRAW_Ax(t5) # x offset
		add t6, t6, t7 
		ldw t6, 0(t6)
		add a0, t1, t6 # new x coordinate
		ldw t6, DRAW_Ay(t5) # y offset
		add t6, t6, t7
		ldw t6, 0(t6)
		add a1, t2, t6 # new y coordinate (a2 has already been saved)
		call push_stack
		call set_gsa 
		call pop_stack
		addi t7, t7, 4 # increment counter
		addi t6, zero, 12
		bne t6, t7, draw_3_squares_loop # exit condition if all 1+3 squares are set
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
	addi sp, sp, -4
	stw ra, 0(sp)
	get_random: 
		#ldw t0, RANDOM_NUM(zero)
		addi t0, zero, B # CHEAT THE TETROMINO
		andi t0, t0, 0x7 # get last 3 bits with a mask 
		cmpge t1, t0, zero # x >= 0
		cmplti t2, t0, 0x5 # x <= 4
		and t1, t1, t2 # check both cond
		beq t1, zero, get_random
	# store correct tetromino informations in memory
	stw t0, T_type(zero)
	addi t0, zero, START_X
	stw t0, T_X(zero)
	addi t0, zero, START_Y
	stw t0, T_Y(zero)
	addi t0, zero, N
	stw t0, T_orientation(zero)
	addi a0, zero, FALLING
	call draw_tetromino # draw given tetromino
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:generate_tetromino

; BEGIN:detect_collision
detect_collision:
	addi sp, sp, -4
	stw ra, 0(sp)

	add t0, a0, zero
	ldw t1, T_X(zero)
	ldw t2, T_Y(zero)
	ldw t3, T_orientation(zero)
	ldw t4, T_type(zero)

	slli a0, t4, 2 # *4 to select appropriate location in DRAW_Ax
	add a0, a0, t3 # incremented by orientation for the triplet
	slli a0, a0, 2 # *4 again

	addi t5, zero, E_COL
	beq t0, t5, E_COL_check

	addi t5, zero, W_COL
	beq t0, t5, W_COL_check

	addi t5, zero, So_COL
	beq t0, t5, So_COL_check

	OVERLAP_check:
		add a1, t1, zero
		add a2, t2, zero
		call push_stack
		call collision_at_position
		call pop_stack
		beq v0, zero, no_collision
		br collision

	E_COL_check:
		addi a1, t1, 1
		add a2, t2, zero
		call push_stack
		call collision_at_position
		call pop_stack
		beq v0, zero, no_collision
		br collision

	W_COL_check:
		addi a1, t1, -1
		add a2, t2, zero
		call push_stack
		call collision_at_position
		call pop_stack
		beq v0, zero, no_collision
		br collision

	So_COL_check:
		add a1, t1, zero
		addi a2, t2, 1
		call push_stack
		call collision_at_position
		call pop_stack
		beq v0, zero, no_collision
		br collision
	
	collision:
		add v0, t0, zero
		br end
	no_collision:
		addi v0, zero, NONE
		br end 
	end:	
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
; END:detect_collision

; BEGIN:rotate_tetromino
rotate_tetromino:
	ldw t0, T_orientation(zero)
	addi t1, zero, rotR
	beq t1, a0, rot_clockwise
	rot_counterclockwise:
		addi t0, t0, -1
		cmplti t1, t0, N
		beq zero, t1, update_orientation
		addi t0, zero, 0x3
		br update_orientation
	rot_clockwise:
		addi t0, t0, 1
		addi t1, zero, ORIENTATION_END
		bne t0, t1, update_orientation
		add t0, zero, zero
	update_orientation:
		stw t0, T_orientation(zero)
	ret
; END:rotate_tetromino

; BEGIN:act
act:
	addi sp, sp, -4
	stw ra, 0(sp)
	add t0, zero, a0
	addi t1, zero, moveL
	beq t0, t1, move_left
	addi t1, zero, rotL
	beq t0, t1, rotate
	addi t1, zero, reset
	beq t0, t1, act_reset
	addi t1, zero, rotR
	beq t0, t1, rotate
	addi t1, zero, moveR
	beq t0, t1, move_right
	addi t1, zero, moveD
	beq t0, t1, move_down
	move_down:
		call push_stack
		addi a0, zero, So_COL
		call detect_collision
		call pop_stack
		addi t0, zero, So_COL
		beq v0, t0, update_pos_skipped
		ldw t0, T_Y(zero)
		addi t0, t0, 1
		stw t0, T_Y(zero)
		br update_pos_moved
	move_right:
		call push_stack
		addi a0, zero, E_COL
		call detect_collision
		call pop_stack
		addi t0, zero, E_COL
		beq v0, t0, update_pos_skipped
		ldw t0, T_X(zero)
		addi t0, t0, 1
		stw t0, T_X(zero)
		br update_pos_moved
	move_left:
		call push_stack
		addi a0, zero, W_COL
		call detect_collision
		call pop_stack
		addi t0, zero, W_COL
		beq v0, t0, update_pos_skipped
		ldw t0, T_X(zero)
		addi t0, t0, -1
		stw t0, T_X(zero)
		br update_pos_moved
	rotate:
		# save initial position
		ldw t0, T_X(zero)
		ldw t1, T_Y(zero)
		ldw t2, T_orientation(zero)
		# rotate tetromino (change his orientation)
		call push_stack
		call rotate_tetromino
		call pop_stack
		# check if there is any overlap
		call push_stack
		addi a0, zero, OVERLAP		
		call detect_collision
		call pop_stack
		addi t3, zero, OVERLAP 
		bne v0, t3, update_pos_moved
		# there is an overlap, move towards center [TODO: move correct direction in extreme cases]
		first_shift:
			cmpgei t3, t0, 6
			beq t3, zero, toward_center_right1
			toward_center_left1:
				addi t3, t0, -1
				stw t3, T_X(zero)
				br second_part
			toward_center_right1:
				addi t3, t0, 1
				stw t3, T_X(zero) 
		second_part:
		# check if there is any overlap
		call push_stack
		addi a0, zero, OVERLAP		
		call detect_collision
		call pop_stack
		addi t3, zero, OVERLAP 
		bne v0, t3, update_pos_moved
		# there is an overlap, move towards center [TODO: move correct direction in extreme cases]
		second_shift:
			cmpgei t3, t0, 6
			beq t3, zero, toward_center_right2
			toward_center_left2:
				addi t3, t0, -1
				stw t3, T_X(zero)
				br last_part
			toward_center_right2:
				addi t3, t0, 1
				stw t3, T_X(zero) 
		last_part:
		# check if there is any overlap
		call push_stack
		addi a0, zero, OVERLAP		
		call detect_collision
		call pop_stack
		addi t3, zero, OVERLAP 
		bne v0, t3, update_pos_moved
		stw t0, T_X(zero)
		stw t1, T_Y(zero)
		stw t2, T_orientation(zero)
		br update_pos_skipped
	act_reset:
		call push_stack
		call reset_game
		call pop_stack
		br end_act 
	update_pos_moved:
	addi v0, zero, 0
	br end_act
	update_pos_skipped:
	addi v0, zero, 1
	end_act:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:act

; BEGIN:get_input
get_input:
	ldw t0, BUTTONS+4(zero)
	andi t1, t0, 1
	addi v0, zero, moveL
	bne t1, zero, end_get_input
	srli t0, t0, 1
	andi t1, t0, 1
	addi v0, zero, rotL
	bne t1, zero, end_get_input
	srli t0, t0, 1
	andi t1, t0, 1
	addi v0, zero, reset
	bne t1, zero, end_get_input
	srli t0, t0, 1
	andi t1, t0, 1
	addi v0, zero, rotR
	bne t1, zero, end_get_input
	srli t0, t0, 1
	andi t1, t0, 1
	addi v0, zero, moveR
	bne t1, zero, end_get_input
	add v0, zero, zero
	end_get_input:
	stw zero, BUTTONS+4(zero)
	ret 
; END:get_input

; BEGIN:detect_full_line
detect_full_line:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t0, zero, Y_LIMIT # t0 = y starting from 8 to 0
	loop_detect_full_line_y:
		addi t0, t0, -1
		addi t3, zero, -1
		beq t0, t3, no_full_lines
		addi t1, zero, X_LIMIT # t1 = x starting from 12 to 0
		addi t2, zero, 1 # t2 = all x from line y are 1 (marker)
		loop_detect_full_line_x:
			addi t1, t1, -1
			call push_stack
			add a0, zero, t1 # a0 = x
			add a1, zero, t0 # a1 = y
			call get_gsa
			call pop_stack
			and t2, t2, v0
			beq t2, zero, loop_detect_full_line_y
			bne t1, zero, loop_detect_full_line_x

	add v0, zero, t0 # v0 = smallest y st for all x : gsa(x,y) = 1/2
	br end_detect_full_line
	no_full_lines: 
	addi v0, zero, Y_LIMIT 
	end_detect_full_line:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:detect_full_line

; BEGIN:remove_full_line
remove_full_line: # A MODULARISER !! 
	addi sp, sp, -4
	stw ra, 0(sp)
	add t0, zero, a0 # t0 = y (full line)
	
	addi t1, zero, X_LIMIT # t1 = x starting from 12 to 0
	loop_remove_full_line_x1:
		addi t1, t1, -1
		call push_stack
		add a0, zero, t1 # a0 = x
		add a1, zero, t0 # a1 = y
		addi a2, zero, NOTHING # a2 = p = nothing
		call set_gsa
		call pop_stack
		bne t1, zero, loop_remove_full_line_x1
	
	call push_stack
	call draw_gsa
	call wait
	call pop_stack

	addi t1, zero, X_LIMIT # t1 = x starting from 12 to 0
	loop_remove_full_line_x2:
		addi t1, t1, -1
		call push_stack
		add a0, zero, t1 # a0 = x
		add a1, zero, t0 # a1 = y
		addi a2, zero, PLACED # a2 = p = placed
		call set_gsa
		call pop_stack
		bne t1, zero, loop_remove_full_line_x2

	call push_stack
	call draw_gsa
	call wait
	call pop_stack

	addi t1, zero, X_LIMIT # t1 = x starting from 12 to 0
	loop_remove_full_line_x3:
		addi t1, t1, -1
		call push_stack
		add a0, zero, t1 # a0 = x
		add a1, zero, t0 # a1 = y
		addi a2, zero, NOTHING # a2 = p = nothing
		call set_gsa
		call pop_stack
		bne t1, zero, loop_remove_full_line_x3

	call push_stack
	call draw_gsa
	call wait
	call pop_stack

	addi t1, zero, X_LIMIT # t1 = x starting from 12 to 0
	loop_remove_full_line_x4:
		addi t1, t1, -1
		call push_stack
		add a0, zero, t1 # a0 = x
		add a1, zero, t0 # a1 = y
		addi a2, zero, PLACED # a2 = p = placed
		call set_gsa
		call pop_stack
		bne t1, zero, loop_remove_full_line_x4

	call push_stack
	call draw_gsa
	call wait
	call pop_stack

	# REMOVE DEFINITELY THE LINE, MOVE ALL UPPER PIXELS ONE LINE DOWN

	loop_remove_full_line_y:
		beq t1, zero, last_step_remove_full_line
		addi t1, t0, -1 # t1 = line above full line (y-1)
		addi t2, zero, X_LIMIT # # t2 = x starting from 12 to 0
		loop_remove_full_line_x:
			addi t2, t2, -1
			call push_stack
			add a0, zero, t2 # a0 = x
			add a1, zero, t1 # a1 = y - 1
			call get_gsa
			add a1, zero, t0 # a1 = y 
			add a2, zero, v0 # a2 = p of y - 1
			call set_gsa
			call pop_stack
			bne t2, zero, loop_remove_full_line_x
		addi t0, t0, -1
		br loop_remove_full_line_y

	last_step_remove_full_line: 
		addi t2, zero, X_LIMIT # # t2 = x starting from 12 to 0
		loop_remove_full_line_x_ls:
			addi t2, t2, -1
			call push_stack
			add a0, zero, t2 # a0 = x
			add a1, zero, t0 # a1 = y 
			addi a2, zero, NOTHING # a2 = p = nothing
			call set_gsa
			call pop_stack
			bne t2, zero, loop_remove_full_line_x_ls
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:remove_full_line

; BEGIN:increment_score
increment_score:
	ldw t0, SCORE(zero)
	cmplti t1, t0, 0x3E8 # t1 = score < 1000
	beq t1, zero, end_increment_score
	addi t0, t0, 1
	stw t0, SCORE (zero)
	end_increment_score:
	ret
; END:increment_score

; BEGIN:display_score
display_score:
	ldw t0, SCORE(zero)
	add t1, zero, t0 # unit
	add t2, zero, t0 # decimal
	add t3, zero, t0 # decimal squared
	
	loop_to_get_unit:
	cmplti t4, t1, 10
	bne t4, zero, get_decimal
	addi t1, t1, -10
	br loop_to_get_unit
	
	get_decimal:
	sub t2, t2, t1
	add t5, zero, zero
	loop_to_get_decimal:
	cmplti t4, t2, 100
	bne t4, zero, get_unit_decimal
	addi t2, t2, -100
	br loop_to_get_decimal
	get_unit_decimal:
	beq t2, zero, end_decimal
	addi t2, t2, -10
	addi t5, t5, 1
	br get_unit_decimal
	end_decimal:
	add t2, zero, t5
	
	get_decimal_squared:
	slli t4, t2, 3
	add t4, t4, t2
	add t4, t4, t2
	sub t3, t3, t4
	sub t3, t3, t1
	add t4, zero, zero
	get_unit_decimal_squared:
	beq t3, zero, end_decimal_squared
	addi t3, t3, -100
	addi t4, t4, 1
	br get_unit_decimal_squared
	end_decimal_squared:
	add t3, zero, t4
	
	slli t1, t1, 2
	slli t2, t2, 2
	slli t3, t3, 2
	
	ldw t1, font_data(t1)
	ldw t2, font_data(t2)
	ldw t3, font_data(t3)
	
	stw t1, SEVEN_SEGS+12(zero)
	stw t2, SEVEN_SEGS+8(zero)
	stw t3, SEVEN_SEGS+4(zero)
	ret
; END:display_score

; BEGIN:reset_game
reset_game:
	addi sp, sp, -4
	stw ra, 0(sp)
	stw zero, SCORE(zero) 
	call clear_leds
	call generate_tetromino
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:reset_game

; BEGIN:helper
push_stack:
	addi sp, sp, -48
	stw a0, 44(sp)
	stw a1, 40(sp)
	stw a2, 36(sp)
	stw a3, 32(sp)
	stw t0, 28(sp)
	stw t1, 24(sp)
	stw t2, 20(sp)
	stw t3, 16(sp)
	stw t4, 12(sp)
	stw t5, 8(sp)
	stw t6, 4(sp)
	stw t7, 0(sp)
	ret

pop_stack:
	ldw t7, 0(sp)
	ldw t6, 4(sp)
	ldw t5, 8(sp)
	ldw t4, 12(sp)
	ldw t3, 16(sp)
	ldw t2, 20(sp)
	ldw t1, 24(sp)
	ldw t0, 28(sp)
	ldw a3, 32(sp)
	ldw a2, 36(sp)
	ldw a1, 40(sp)
	ldw a0, 44(sp)
	addi sp, sp, 48
	ret

collision_at_position:
	addi sp, sp, -4 
	stw ra, 0(sp)
	
	add t5, a0, zero
	add t1, a1, zero
	add t2, a2, zero
	addi t7, zero, 0 # initialize counter
	collision_at_position_loop:
		ldw t6, DRAW_Ax(t5) # x offset
		add t6, t6, t7 
		ldw t6, 0(t6)
		add a0, t1, t6 # new x coordinate
		ldw t6, DRAW_Ay(t5) # y offset
		add t6, t6, t7
		ldw t6, 0(t6)
		add a1, t2, t6 # new y coordinate (a2 has already been saved)

		call push_stack
		call in_gsa
		call pop_stack
		addi t6, zero, 1
		beq t6, v0, collision_at_position_detected

		call push_stack
		call get_gsa
		call pop_stack
		addi t6, zero, PLACED
		beq v0, t6, collision_at_position_detected
		
		addi t7, t7, 4 # increment counter
		addi t6, zero, 12
		bne t6, t7, collision_at_position_loop # exit condition if all 1+3 squares are set

	collision_at_position_not_detected:
		addi v0, zero, 0
		br collision_at_position_end
	collision_at_position_detected:
		addi v0, zero, 1
		br collision_at_position_end
	
	collision_at_position_end:
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret

test_for_rotation_to_be_deleted:
	call generate_tetromino
	call draw_gsa
	addi a0, zero, rotL
	call act
	addi a0, zero, moveD
	call act
	call act
	call act
	addi a0, zero, moveR
	call act
	call act
	call act
	call act
	call act
	addi a0, zero, rotL
	call act
	addi a0, zero, moveL
	call act
	call act
	addi a0, zero, moveD
	call act
	call act
	call act
	call act
	call act
	break

test2:
	call generate_tetromino
	call draw_gsa
	add v0, zero, zero
	add a0, zero, zero
	addi a1, zero, 5
	addi a2, zero, PLACED
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	addi a0, a0, 1
	call set_gsa
	call draw_gsa
	call detect_full_line
	add a0, zero, v0
	call remove_full_line
	call draw_gsa
	break 

test:
	call generate_tetromino
	call draw_gsa
	addi a0, zero, moveR
	call act
	call act
	call act
	addi a0, zero, moveD
	call act
	call act
	call act
	call act
	call act	
	call act
	call act
	call generate_tetromino
	addi a0, zero, moveL
	call act
	call act
	call act
	call act
	call act
	addi a0, zero, moveD
	call act
	call act
	call act
	call act
	call act
	call act
	call act
	call generate_tetromino
	addi a0, zero, moveL
	call act
	addi a0, zero, moveD
	call act
	call act
	call act
	call act
	call act
	call act
	call act
	call detect_full_line
	add a0, zero, v0
	call remove_full_line
	break
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