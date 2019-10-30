;; tetris game

;; game state memory location
.equ T_X,           0x1000    ; falling tetromino position on x
.equ T_Y,           0x1004    ; falling tetromino position on y
.equ T_type,        0x1008    ; falling tetromino type
.equ T_orientation, 0x100C    ; falling tetromino orientation
.equ SCORE,         0x1010    ; score
.equ GSA,           0x1014    ; Game State Array starting address
.equ SEVEN_SEGS,    0x1198    ; 7-segment display addresses
.equ LEDS,          0x2000    ; LED address
.equ RANDOM_NUM,    0x2010    ; Random number generator address
.equ BUTTONS,       0x2030    ; Buttons addresses

;; tetromino type enumeration
.equ C, 0x00                  ; carre (square)
.equ B, 0x01                  ; bar-shape
.equ T, 0x02                  ; t-shape
.equ S, 0x03                  ; s-shape
.equ L, 0x04                  ; l-shape

;; GSA type
.equ NOTHING, 0x00			  ; the array location is not occupied
.equ PLACED,  0x01			  ; occupied by a nonmoving object
.equ FALLING, 0x02			  ; occupied by a falling object

;; orientation enumeration
.equ N,  0x00				  ; north
.equ E,  0x01				  ; east
.equ So, 0x02				  ; south
.equ W,  0x03				  ; west

;; rotation enumeration
.equ CLOCKWISE, 0			  ; clockwise direction of rotation
.equ COUNTERCLOCKWISE, 1	  ; counterclockwise direction of rotation

;; actions over tetrominoes
.equ moveL, 0x01			  ; move left, horizontally
.equ rotL,  0x02			  ; rotate counterclockwise
.equ reset, 0x04			  ; reset the game
.equ rotR,  0x08			  ; rotate clockwise
.equ moveR, 0x10			  ; move right, horizontally
.equ moveD, 0x20			  ; move down, vertically

;; collision return enum
.equ W_COL,   0x00			  ; collision on the west side of tetrominoe
.equ E_COL,   0x01			  ; collision on the east side of tetrominoe
.equ So_COL,  0x02 			  ; collision on the south side of tetrominoe
.equ OVERLAP, 0x03			  ; tetromino overlaps with something
.equ NONE,    0x04			  ; tetromino does not collide with anything

;; start location
.equ START_X, 6				  ; start tetromino x-axis coordinate
.equ START_Y, 1				  ; start tetromino y-axis coordinate

;; standard limits 
.equ X_LIMIT, 12
.equ Y_LIMIT, 8

;; game rate of tetrominoes falling down (in terms of game loop iteration)
.equ RATE, 5












