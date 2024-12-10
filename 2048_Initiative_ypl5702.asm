# Yifan Liu 2048 Project
.data
	board:  .word 0:16				#A 4x4 2d array to represent the board
	avaliableS: .word 17:16				#A 4x4 2d array to hold available spaces
	tempBoard: .word 0:16				#A 4x4 2d array to hold the next state of the board after a move
	transBoard: .word 0:16				#A 4x4 2d array to hold the transpose of the board for move up and down
	
	score: .word 0
	
	#color table to hold the color codes used by the tiles and numbers
	ColorTable:
		.word 0xeee4da  #Tile 2
		.word 0xede0c8  #Tile 4
		.word 0xf2b179  #Tile 8
		.word 0xf59563  #Tile 16
		.word 0xf67c5f  #Tile 32
		.word 0xf65e3b  #Tile 64
		.word 0xedcf72  #Tile 128
		.word 0xedcc61  #Tile 256
		.word 0xedc850  #Tile 512
		.word 0xedc53f  #Tile 1024
		.word 0xedc22e  #Tile 2048
		.word 0x000000  # Black
		.word 0xffffff	#white	
		.word 0x333333  #grey
		.word 0x228ced  #light blue 
		
		
	Colors:
	       	 .word   0xffffff        # foreground color (white)
		 .word   0x000000        # background color (black)
		 .word   0x228ced        #light blue
		 .word   0x00cccc	#Aquamarine
		 .word   0x0287c3	#greenish blue

#special digit table to hold hex representations for how to draw each number
	DigitTable:
        	.byte   ' ', 0,0,0,0,0
        	.byte   '0', 0xE0,0xA0,0xA0,0xA0,0xE0
   		.byte   '1', 0x20,0x20,0x20,0x20,0x20
   		.byte   'l', 0x40,0xC0,0x40,0x40,0xE0
   		.byte   '!', 0x40,0x40,0x40,0x40,0x40
        	.byte   '2', 0xE0,0x20,0xE0,0x80,0xE0
        	.byte   '3', 0xE0,0x20,0xE0,0x20,0xE0
        	.byte   '4', 0xA0,0xA0,0xE0,0x20,0x20
        	.byte   '5', 0xE0,0x80,0xE0,0x20,0xE0
        	.byte   '6', 0xE0,0x80,0xE0,0xA0,0xE0
        	.byte   '8', 0xE0,0xA0,0xE0,0xA0,0xE0
        	
        #	842
        #       |||
        #   1   xxx  0xE0
	#   2   ..x  0x20
	#   3   xxx  0xE0
	#   4   x..  0x80
	#   5   xxx  0xE0
        	
        #digits table to hold digits for the numbers on the tiles
        Digits: 
	      .asciiz "2"	# branch 1
	      .asciiz "4"
	      .asciiz "8"
	      .asciiz "16"	# branch 2
	      .asciiz "32"
	      .asciiz "64"
	      .asciiz "128"	# branch 3
	      .asciiz "256"
	      .asciiz "5!2"
	      
	      
	#large numbers that have to be drawn separately
	thousandOne:
	      .asciiz "l"
	      .asciiz "0"
	      .asciiz "2"
	      .asciiz "4"
	thousandTwo:
	      .asciiz "2"
	      .asciiz "0"
	      .asciiz "4"
	      .asciiz "8"
	
	#Win loss messages
	win: .asciiz "You Win!"
	scd:  .asciiz "Score: "
	loss: .asciiz "Game Over!"
	newL: .asciiz "\n"
.text


#initialization phase
Init:
	jal InitRand								#Set up the random number generator set seed
	jal ClearDisp								#clear the display
	jal DrawBoard								#draws the board
	li $t7, 0								#initialize counter variable
	randLoop:

	jal CreateRandomTile							#spawn in a new random tile 2 or 4
	addi $t7, $t7, 1							#increment counter
	blt $t7, 2, randLoop							#checks if both random tiles have been spawned or not

Main:

	
	#loop until valid move 
	loopVMove:
	jal GetChar		#poll the keyboard display
	move $t0, $v0		#moves the result of the polling to $t0
	beq $t0, 'a', left	#checks for what move has occured
	
	beq $t0, 'w', up
	
	beq $t0, 'd', right
	
	beq $t0, 's', down
	j loopVMove		#if move invalid loop back
	
	#Under each direction label call the move direction procedure and update the board
	left:
	jal MoveLeft		
	jal UpdateBoardVOne
	j newTile
	
	up:
	jal MoveUp
	jal UpdateBoardVTwo
	j newTile

	right:
	jal MoveRight
	jal UpdateBoardVOne
	j newTile
	
	down:
	jal MoveDown
	jal UpdateBoardVTwo
	
	#Under newTile determine if one should be generated
	newTile:
	li $v0, 4		#print score 
	la $a0, scd
	syscall
	li $v0, 1
	la $a0, score
	lw $a0, ($a0)
	syscall
	li $v0, 4
	la $a0, newL
	syscall
	
	la $a0, board
	jal CheckState
	beq $v0, 1, continueG
	beq $v0, 2, displayWin
	j displayLoss
	
	#continue execution
	continueG:
	#clean intermediary matricies
	la $a0, tempBoard
	jal CleanMatrix
	la $a0, transBoard
	jal CleanMatrix
	#check if that move did nothing or not
	bne $v1, 1, loopVMove
	#generate new tile
	jal CreateRandomTile
	#check if the again for if the game is lost or not
	la $a0, board
	jal CheckState
	beq $v0, 0, displayLoss
	#continue main loop
	j Main
	
	#labels that have code to display a win or loss
	displayWin:
	li $v0, 4
	la $a0, win
	syscall
	j exit
	displayLoss:
	li $v0, 4
	la $a0, loss
	syscall 
	j exit
	
#exit the program
exit:
li $v0, 10
syscall

#PROCEDURES____________________________________________________________________________________________________

#Procedure UpdateBoardVOne takes the tempBoard can copies its contents to the actual board

#no arguments 

#no output
UpdateBoardVOne:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, tempBoard
	la $a1, board
	jal CopyMat
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#Procedure UpdateBoardVTwo takes the transBoard can copies its contents to the actual board

#no arguments 

#no output
UpdateBoardVTwo:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, transBoard
	la $a1, board
	jal CopyMat
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#Procedure CheckBoard checks the board for avaliable spaces

#no arguments 

#outputs $v0 which holds the number of open spaces there are
CheckBoard:
	la $t4, board
	la $t5, avaliableS
	li $t0, 0
	li $v0, 0
	bloop:
	    lw $t1, 0($t4)		#loops through the board checking if the board content in that square is 0
	    addi $t4, $t4, 4
	    beq $t1, 0, addtoA
	    addi $t0, $t0, 1		#increments counter
	    j cond
	    
	    addtoA:
	        sw $t0, 0($t5)		#stores that board index if the board content in that square is 0
	        addi $t5, $t5, 4	#increments the available S address
	        addi $t0, $t0, 1	#increments counter
	    	addi $v0, $v0, 1	#increments the number of open spaces there are
	    cond:
	    	blt $t0, 16, bloop	#checks if the entire board has been looped through
	jr $ra
	

#Procedure GenerateIndex generates a index for a new random tile to be placed

#argument $a1 holds the upper bound of the number of open spaces there are 	

#outputs the index for the new random tile 
GenerateIndex:
	la $t0, avaliableS
	li $a0, 0
	li $v0, 42								#Gets a random number with id zero and upper bound a1 not inclusive
	syscall
	sll $t1, $a0, 2								#converts the random number generated into an array offset
	add $t0, $t0, $t1							#adds to the available indexes array address
	lw $v0, ($t0)								#loads the index for the new random tile 
	jr $ra

#Procedure IndexToIndicies converts a board index to a pair of indicies 

#argument $a0 is the board index that has to be converted

#outputs $v0 and $v1 which are the i, j indicies of a 4x4 matrix
IndexToIndicies:
	bge $a0, 12, rowFour		#determines row 
	bge $a0, 8, rowThree
	bge $a0, 4, rowTwo
	li $v0, 0
	move $v1, $a0
	j endConv
	rowFour:
	    li $v0, 3
	    sll $t1, $v0, 2
	    sub $v1, $a0, $t1
	    j endConv
	rowThree:
	    li $v0, 2
	    sll $t1, $v0, 2
	    sub $v1, $a0, $t1
	    j endConv
	rowTwo:
	    li $v0, 1
	    sll $t1, $v0, 2
	    sub $v1, $a0, $t1	
	endConv:
	jr $ra	

#Procedure ConvertIndex converts a single index value to an address of board	

#argument $a0 serves as the index to become offset

#returns the full address of board including the offset
ConvertIndex:
	la $t2, board
	sll $t1, $a0, 2
	add $v0, $t2, $t1
	jr $ra

#Procedure ConvertIndicies converts a pair of indicies to an address of board

#arguments $a0 and $a1 are the i, j indicies of the array

#returns the address of the converted indicies	
	
ConvertIndicies:
	la $t2, board
	sll $t0, $a0, 2
	add $t1, $t0, $a1
	sll $t3, $t1, 2
	add $v0, $t3, $t2
	jr $ra

#Procedure GenerateTwoFour generates a new two or four 

#no arguments 

#returns 2 or 4 stored in $v1

GenerateTwoFour:
	li $a0, 0
	li $v0, 42								#Gets a random number with id zero and upper bound 10 not inclusive (0-9)
	li $a1, 10
	syscall
	bne $a0, 9, two								#tests if that number is 9 or not
	li $v1, 4								#if it is nine then the new number generated is a 4
	j endGen
	two:
	   li $v1, 2								#otherwise it is a 2
	endGen:
	jr $ra

#Procedure that initializes the random number generator

#No arguments 

InitRand:
#Get the current time ($a0 holding the low order 32 bits)
	li $v0, 30
	syscall
	move $a1, $a0								#moves the current time into $a1				
	li $a0, 0
#set seed  ($a0 generator id = 0 and $a1 system time) 
	li $v0, 40
	syscall 
	jr $ra

#Procedure CleanMatrix sets all elements of a 2d array to 0

#arg: $a0 matrix address to clean

#returns nothing 
CleanMatrix:
	li $t9, 0
	forL:
	   sw $0, ($a0)			#store $0 into every array position
	   addi $t9, $t9, 1
	   addi $a0, $a0, 4
	   blt $t9, 16, forL
	jr $ra

#Procedure CopyMat copys elements from 1 2d array to another 2d array 

#args: $a0, $a1 pointers to the addresses of the source and destination arrays 	

#Returns nothing 
CopyMat:
	li $t9, 0
	copyLoop:
	    lw $t0, ($a0)		#load then store into destination
	    sw $t0, ($a1)
	    addi $t9, $t9, 1
	    addi $a0, $a0, 4		#increment both arrays 
	    addi $a1, $a1, 4
	    blt $t9, 16, copyLoop
	 jr $ra

#Procedure CheckState checks the state of board for if there is a win, loss, or whether the game should continue

#arguments: $a0 pointer to the address of board array

#Returns $v0 state of the game 0 loss, 1 continue, 2 win
	 
CheckState:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	li $t9, 0
	#loop thourgh the array to check for 2048 in any tiles if this number exists the game is won 
	stateLoop1:
	    lw $t0, ($a0)
	    beq $t0, 2048, victory	#branch to victory label on win
	    addi $t9, $t9, 1
	    addi $a0, $a0, 4
	    blt $t9, 16, stateLoop1

	    
	lw $a0, 4($sp)
	li $t9, 0
	#loop through to check for the prescence of 0s if there is a 0 present then the game continues 
	stateLoop2:
	    lw $t0, ($a0)
	    beq $t0, 0, contGame	#branch to continue game 
	    addi $t9, $t9, 1
	    addi $a0, $a0, 4
	    blt $t9, 16, stateLoop2
	    
	lw $a0, 4($sp)
	li $t8, 0
	sw $a0, 0($sp)
	#loop thorugh to check if there are potential squares that can be merged 
	stateLoop3:
	    li $t9, 0
	    lw $a0, 0($sp)
	    stateLoop3i:
	    	lw $t0, ($a0)	
	    	addi $t1, $a0, 4	
	    	lw $t2, ($t1)
	  	beq $t0, $t2, contGame	#check horizontally for potential merges
	  	addi $t1, $a0, 16
	  	lw $t2, ($t1)
	  	beq $t0, $t2, contGame	#check vertically for potential merges
	  	addi $a0, $a0, 4
	  	addi $t9, $t9, 1
	  	blt $t9, 3, stateLoop3i
	    addi $t8, $t8, 1
	    lw $a0, 0($sp)
	    addi $a0, $a0, 16
	    sw $a0, 0($sp)
	    blt $t8, 3, stateLoop3 #checks through a 3x3 matrix in both the rows and columns 
	
	#since the 4th row and 4th column have not been verified use two additional loop to check 
	#horizontally in the 4th row and vertically in the 4th column for potential merges    	
	lw $a0, 4($sp)
	addi $a0, $a0, 48
	li $t9, 0
	stateLoop4:
	    lw $t0, ($a0)
	    addi $t1, $a0, 4
	    lw $t2, ($t1)
	    beq $t0, $t2, contGame
	    addi $t9, $t9, 1
	    addi $a0, $a0, 4
	    blt $t9, 3, stateLoop4
	
	lw $a0, 4($sp)
	addi $a0, $a0, 12
	li $t9, 0
	stateLoop5:
	    lw $t0, ($a0)
	    addi $t1, $a0, 16
	    lw $t2, ($t1)
	    beq $t0, $t2, contGame
	    addi $t9, $t9, 1
	    addi $a0, $a0, 16
	    blt $t9, 3, stateLoop5
	    
	    
	li $v0, 0
	j exitStateCheck
	
	victory:
	    li $v0, 2  
	    j exitStateCheck
	    
	contGame:
	    li $v0, 1
	    
	exitStateCheck:
	addi $sp, $sp, 8
	jr $ra
	

#Procedure CreateRandomTile checks the board for available spaces, generates index, converts the index to indices, gets an offset, and generates a 2 or 4, and draws the new random tile

#No arguments 

#no output

CreateRandomTile:
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	jal CheckBoard		#checks for available spaces
	move $a1, $v0
	jal GenerateIndex	#picks one of the available spaces randomly
	move $a0, $v0
	jal IndexToIndicies	#converts the space index to indicies
	move $t5, $v0
	move $t6, $v1
	jal ConvertIndex	#converts space index to an address
	move $t0, $v0
	jal GenerateTwoFour
	sw $v1, ($t0)		#store new 2 or 4 to addressin board
	
	move $a0, $t6		#indicies function as arguments to draw tile
	move $a1, $t5
	move $a2, $v1		#2 or 4 value serves as another arg
	jal DrawTile	
	
	lw $ra, 16($sp)
	addi $sp, $sp, 20
	jr $ra


#Procedure move down shifts and merges tiles down

#no arguments

#no output

MoveDown:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, board
	la $a1, transBoard	#transpose board to transBoard matrix
	jal TransposeMat
	li $a0, 1
	jal MaxShiftR		#shifting right is the same as moving down on this transposed matrix
	la $a0, tempBoard	#transpose tempBoard to transBoard which will hold the result of moving down 
	la $a1, transBoard
	jal TransposeMat
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#Procedure move right shifts and merges tiles right

#no arguments

#no output

MoveRight:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal MaxShiftR		#calls the maxShiftR function to handle shifting and mergin right 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#Procedure move up shifts and merges tiles up

#no arguments

#no output

MoveUp:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, board
	la $a1, transBoard	#transpose board to transBoard matrix
	jal TransposeMat
	li $a0, 1
	jal MaxShiftL 		#shifting left is the same as moving up on this transposed matrix
	la $a0, tempBoard	#transpose tempBoard to transBoard which will hold the result of moving up
	la $a1, transBoard
	jal TransposeMat
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#Procedure move left shifts and merges tiles left

#no arguments

#no output
MoveLeft:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal MaxShiftL
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#Note: the use of the two extremly similar MaxShift functions is to prevent overburdening the MaxShiftL function with branch statements 
#this implementation is similar to the considerations between having separate functions for drawing vertical and horizontal lines 

#Procedure MaxShiftL shifts and merges tiles left in a row 

#argument $a0 holds the value of whether this is a move up operation or a move left operation

#returns $v1 which is a boolean value 1 (if a merge or shift occured)

MaxShiftL:
	addi $sp, $sp, -24
	sw $s5, 20($sp)
	sw $s4, 16($sp)
	sw $s0, 12($sp)
	sw $ra, 8($sp)
	add $s4, $0, $a0
	beq $s4, 1, loadTB		#check if to load board or transboard
	la $t5, board
	j contLoad
	loadTB:
	la $t5, transBoard
	contLoad:
	la $t6, tempBoard
	sw $t5, 4($sp)
	sw $t6, 0($sp)
	li $t8, 0			#counters

	outerLoop:
		li $t9, 0		#column counter reset each outer loop	column counter for board or transboard
		li $t7, 0		#currently open column in row index     column counter for tempBoard
		innerLoop:
			lw $t2, ($t5)
			beq $t2, 0, skip		#check if a shift is needed
			beq $s0, 1, noMerge		#check if a merge is needed 
			bgt $t7, $0, detectMerge
			j noMerge
			
			detectMerge:
			    lw $t3, ($t4) 	#loads the previous column value
			    beq $t2, $t3, mergeT
			    j noMerge
			    mergeT:
			    	beq $s4, 1, coordTransC	#check if the operation is move up or more left
			   	add $a0, $0, $t9 	#move left destory current tile
			    	add $a1, $0, $t8
			    	j doDestroyC
			    	coordTransC:
			    	add $a0, $0, $t8	#move up destroy current tile (notice the reversal in arguments to provide an on demand transpose)
			    	add $a1, $0, $t9
			    	doDestroyC:
			   	jal DestroyTile		
			   	sll $t3, $t3, 1		#takes the previous column value and multiplies it by 2 which gets the post merge value 
			   	
			   	la $s5, score 
			   	lw $t0, ($s5)
			   	add $t0, $t0, $t3
			   	sw $t0, ($s5)
			   	
			   	sw $t3, ($t4)		#stores this value into the previous column value address 
			   	addi $t0, $t7, -1	#subtract 1 from the column counter for tempBoard
			   	beq $s4, 1, coordTransA
			   	add $a0, $0, $t0	#move left draw new tile
			   	add $a1, $0, $t8
			   	j doDrawA
			   	coordTransA:
			   	add $a0, $0, $t8	#move up draw new tile (notice the reversal in arguments to provide an on demand transpose)
			   	add $a1, $0, $t0
			   	doDrawA:
			    	add $a2, $0, $t3
			   	jal DrawTile
			   	li $s0, 1		#set $s0 to 1 this signifies to not check for merge on the next loop to prevent overmerging 
			   	li $v1, 1		#signal that a change to the board has occurred
				j skip
			
			noMerge:
			add $t4, $0, $t6  	 #stores the current address in $t4 to load the previous column value in merging 
			
			sw $t2, ($t6)	   	 #stores into copy tempBoard

			addi $t6, $t6, 4   	 #next
			li $s0, 0          	 #set $s0 to 0 to ensure checking for merges
			bne $t7, $t9, shifts

			addi $t7, $t7, 1	#increments the column counter for tempBoard
			j skip
			
			shifts:				#deal with shifts here
			    beq $s4, 1, coordTransD
			    add $a0, $0, $t9		#move left destory current tile 
			    add $a1, $0, $t8
			    j doDestroyD
			    coordTransD:
			    add $a0, $0, $t8		#move up destroy current tile 
			    add $a1, $0, $t9
			    doDestroyD:
			    jal DestroyTile
			    beq $s4, 1, coordTransB
			    add $a0, $0, $t7		#move left draw new tile 
			    add $a1, $0, $t8
			    j doDrawB
			    coordTransB:
			    add $a0, $0, $t8		#move up draw new tile 
			    add $a1, $0, $t7
			    doDrawB:
			    add $a2, $0, $t2
			    jal DrawTile
			    addi $t7, $t7, 1		#increment the column counter for tempBoard
			    li $v1, 1			#signal that a change to the board has occurred
		skip:
	
		addi $t9, $t9, 1	#increment the column counter for board or transboard
		addi $t5, $t5, 4	#increment the address for board or transboard 
		blt $t9, 4, innerLoop
	
	addi $t8, $t8, 1		#increment the row counter 	
	lw $t6, 0($sp)
	lw $t5, 4($sp)
	addi $t6, $t6, 16		#move both addresses down a line 
	addi $t5, $t5, 16
	sw $t5, 4($sp)
	sw $t6, 0($sp)
	blt $t8, 4, outerLoop		#check if all the rows of board or transboard have been looped through 
	#end outer loop
	
	lw $ra, 8($sp)
	lw $s0, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	addi $sp, $sp, 24
	jr $ra

#Procedure MaxShiftR shifts and merges tiles right in a row 

#argument $a0 holds the value of whether this is a move down operation or a move right operation

#returns $v1 which is a boolean value 1 (if a merge or shift occured)

MaxShiftR:
	addi $sp, $sp, -24
	sw $s5, 20($sp)
	sw $s4, 16($sp)
	sw $s0, 12($sp)
	sw $ra, 8($sp)
	add $s4, $0, $a0
	beq $s4, 1, loadTBR
	la $t5, board
	addi $t5, $t5, 12		#the main difference between MaxShiftR from MaxShiftL is that everything here is decremented from the end of a row to the beginning
	j contLoadR
	loadTBR:
	la $t5, transBoard
	addi $t5, $t5, 12
	contLoadR:
	la $t6, tempBoard
	addi $t6, $t6, 12
	sw $t5, 4($sp)
	sw $t6, 0($sp)
	li $t8, 0			#counters

	outerLoopR:
		li $t9, 3
		li $t7, 3		#currently open column in row
		innerLoopR:
			lw $t2, ($t5)
			beq $t2, 0, skipR
			beq $s0, 1, noMergeR
			blt $t7, 3, detectMergeR
			j noMergeR
			
			detectMergeR:
			    lw $t3, ($t4) 	#loads the previous column value
			    beq $t2, $t3, mergeTR
			    j noMergeR
			    mergeTR:
			    	beq $s4, 1, coordTransCR
			   	add $a0, $0, $t9
			    	add $a1, $0, $t8
			    	j doDestroyCR
			    	coordTransCR:
			    	add $a0, $0, $t8
			    	add $a1, $0, $t9
			    	doDestroyCR:
			   	jal DestroyTile
			   	sll $t3, $t3, 1
			   	
			   	la $s5, score 
			   	lw $t0, ($s5)
			   	add $t0, $t0, $t3
			   	sw $t0, ($s5)
			   	
			   	sw $t3, ($t4)
			   	addi $t0, $t7, 1
			   	beq $s4, 1, coordTransAR
			   	add $a0, $0, $t0
			   	add $a1, $0, $t8
			   	j doDrawAR
			   	coordTransAR:
			   	add $a0, $0, $t8
			   	add $a1, $0, $t0
			   	doDrawAR:
			    	add $a2, $0, $t3
			   	jal DrawTile
			   	li $s0, 1
			   	li $v1, 1
				j skipR
			
			noMergeR:
			add $t4, $0, $t6   #stores the curr/prev
			
			sw $t2, ($t6)

			addi $t6, $t6, -4   #next
			li $s0, 0
			bne $t7, $t9, shiftsR

			addi $t7, $t7, -1
			j skipR
			
			shiftsR:
			    beq $s4, 1, coordTransDR
			    add $a0, $0, $t9
			    add $a1, $0, $t8
			    j doDestroyDR
			    coordTransDR:
			    add $a0, $0, $t8
			    add $a1, $0, $t9
			    doDestroyDR:
			    jal DestroyTile
			    beq $s4, 1, coordTransBR
			    add $a0, $0, $t7
			    add $a1, $0, $t8
			    j doDrawBR
			    coordTransBR:
			    add $a0, $0, $t8
			    add $a1, $0, $t7
			    doDrawBR:
			    add $a2, $0, $t2
			    jal DrawTile
			    addi $t7, $t7, -1
			    li $v1, 1
			    
		skipR:
	
		addi $t9, $t9, -1
		addi $t5, $t5, -4
		bge $t9, 0, innerLoopR
	
	addi $t8, $t8, 1
	lw $t6, 0($sp)
	lw $t5, 4($sp)
	addi $t6, $t6, 16
	addi $t5, $t5, 16
	sw $t5, 4($sp)
	sw $t6, 0($sp)
	blt $t8, 4, outerLoopR
	#end outer loop
	
	lw $ra, 8($sp)
	lw $s0, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	addi $sp, $sp, 24
	jr $ra


#Procedure Transpose Matrix tranposes an array and stores it in a target array 

#Arguments 

#$a0 pointer to the source array address

#$a1 pointer to the target array address

#returns nothing 

TransposeMat:
	addi $sp, $sp, -24
	sw $t9, 20($sp)
	sw $t8, 16($sp)
	sw $s2, 12($sp)
	sw $s1, 8($sp)
	add $t0, $0, $a0
	add $t1, $0, $a1
	sw $t0, 4($sp)
	sw $t1, 0($sp)
	li $t8, 0
	tLoopA:				#uses a nested for loop to loop through the arrays and perform the transpose
	    li $t9, 0
	    tLoopB:
	        lw $s1, ($t0)
	        sw $s1, ($t1)		#store into target
	        addi $t0, $t0, 4	#loop source array horizontally
	        addi $t1, $t1, 16	#loop the other array through vertically
		addi $t9, $t9, 1
		blt $t9, 4, tLoopB
	    
	    addi $t8, $t8, 1
	    lw $t1, 0($sp)
	    lw $t0, 4($sp)
	    addi $t0, $t0, 16		#moves the source array to the next row
	    addi $t1, $t1, 4		#move the other array to the next column 
	    sw $t0, 4($sp)
	    sw $t1, 0($sp)
	    blt $t8, 4, tLoopA
	    
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $t8, 16($sp)
	lw $t9, 20($sp)
	addi $sp, $sp, 24    
	jr $ra

	    


#Is character present

#Returns $v0 = 0 (no data), or 1 (character is in the buffer)
IsCharThere:
	lui $t0, 0xffff					# reg @ 0xffff0000
	lw $t1, 0($t0)					# get control
	and $v0, $t1, 1					# look at least significant bit
	jr $ra


#Poll the keypad, wait for an input character

#returns with $v0 = Ascii character

GetChar:
	addiu $sp, $sp, -4
	sw $ra, 0($sp)					#store ra
	cloop:
		jal IsCharThere				
		beq $v0, $0, cloop			#if no data try later
		lui $t0, 0xffff				#char in 0xffff0004		
		lw $v0, 4($t0)
		lw $ra, 0($sp)				#restore ra
		addiu $sp, $sp, 4
		jr $ra
















#DRAW PROCEDURES__________________________________________________________________________________________


#Procedure to draw a dot	

#arguments:

# $a0 = x coordinate (0-63)

# $a1 = y coordinate (0-63)

# $a2 = color number (0-7)

#No output
DrawDot:
	addiu $sp, $sp, -8				#make room on stack, 2 words
	sw $ra, 4($sp)					#store $ra
	sw $a2, 0($sp)					#store $a2
	jal CalcAddress					#$v0 has address for pixedl
	lw $a2, 0($sp)					#restore $a2
	sw $v0, 0($sp)					#save $v0	
	jal GetColor					#$v1 new holds color
	lw $v0, 0($sp)					#restore $v0
	sw $v1, 0($v0)					#make dot
	lw $ra, 4($sp)					#load/restore original $ra
	addiu $sp, $sp, 8				#adjust $sp to deallocate stack
	jr $ra


# Function to convert X,Y coordinate to address

#arguments:

# $a0 = x coordinate (0-63)

# $a1 = y coordinate (0-63)

# returns $v0 = memory address

CalcAddress: 
	la $t0, 0x10040000
	#$v0 = base + $a0 *4 + $a1 * 64 *4
	sll $t1, $a0, 2					#x coordinate times 4
	add $v0, $t0, $t1				#add the computed $a0 
	sll $t1, $a1, 6					#multiply by 64		
	sll $t1, $t1, 2					#multiply by 4
	add $v0, $v0, $t1				
	jr $ra


# Function to get color hex from memory

#arguments:
	
#$a2 = color number (0-7)

#returns $v1 = actual number to write to the display
GetColor:
	la $t0, ColorTable				#load base
	sll $a2, $a2, 2					#index x4 is offset
	add $a2, $t0, $a2				#addess is base + offset
	lw $v1, 0($a2)					#get actual color from memory
	jr $ra
	
	
	
#Procedure to draw a horizontal line 

# arguments:
	
# $a0 = x coordinate (0-63)

# $a1 = y coordinate (0-63)

# $a2 = color number (0-7)

# $a3 = length of the line (1-64)

#No output
HorzLine:
	addiu $sp, $sp, -20				#create stack frame/save $ra, $a1, $a2
	sw $ra, 16($sp)					#saves $ra, $a1, $a2
	sw $a1, 12($sp)
	sw $a2, 8($sp)
HorzLoop:
	#store a regs
	sw $a0, 4($sp)					#stores x coord and length
	sw $a3, 0($sp)
	jal DrawDot					#calls the draw dot procedure
	#restores a regs
	lw $a3, 0($sp)					#restores x coore, length, and color num
	lw $a0, 4($sp)
	lw $a2, 8($sp)	
	
	addi $a0, $a0, 1				#increment x coord ($a0)
	addi $a3, $a3, -1				#decrement line left ($a3)
	bne $a3, $0, HorzLoop				#continues to draw the line if line left >0
	
	lw $a2, 8($sp)					#restore $ra, $a1, $a2, $sp
	lw $a1, 12($sp)
	lw $ra, 16($sp)
	addiu $sp, $sp, 20				
	jr $ra	
	
	
	
	
#Procedure to draw a vertical line 

#arguments:

# $a0 = x coordinate (0-63)

# $a1 = y coordinate (0-63)

# $a2 = color number (0-7)

# $a3 = length of the line (1-64)

#No output	
VertLine:
	addiu $sp, $sp, -20				#create stack frame/save $ra, $a0, $a2
	sw $ra, 16($sp)					
	sw $a0, 12($sp)
	sw $a2, 8($sp)
	
VertLoop:
	#store a regs
	sw $a1, 4($sp)					#stores y coord and length of line 
	sw $a3, 0($sp)
	jal DrawDot					#calls the drawdot procedure
	#restores a regs
	lw $a3, 0($sp)					#restores y coord, length of line, and color num 
	lw $a1, 4($sp)
	lw $a2, 8($sp)	
	
	addi $a1, $a1, 1				#increment y coord ($a1)
	addi $a3, $a3, -1				#decrement line left ($a3)
	bne $a3, $0, VertLoop				#continues to draw the line if line left >0
	
	lw $a2, 8($sp)					#restore $ra, $a0, $a2, $sp
	lw $a0, 12($sp)
	lw $ra, 16($sp)
	addiu $sp, $sp, 20
	jr $ra	
	


	
#Procedure to draw a box using horizontal lines 
	
#arguments:

# $a0 = x coordinate (0-63)

# $a1 = y coordinate (0-63)

# $a2 = color number (0-7)

# $a3 = size of box (1-64)	

#No output
DrawBox:
	addiu $sp, $sp, -24				#create stack frame/save $ra and $s0
	sw $ra, 20($sp)					
	sw $s0, 16($sp)
	#copy $a3 -> temp register $s0
	add $s0, $0, $a3				
BoxLoop:
	sw $a3, 12($sp)					#save a regs to stack 
	sw $a0, 8($sp)					
	sw $a1, 4($sp)
	sw $a2, 0($sp)
	jal HorzLine					#Calls the HorzLine procedure with args a0, a1, a2, a3
	lw $a2, 0($sp)					#restore a regs to stack 
	lw $a1, 4($sp)
	lw $a0, 8($sp)						
	lw $a3, 12($sp)
	
	addi $a1, $a1, 1				#increment y coordinate 
	addiu $s0, $s0, -1				#decrement counter
	bne $s0, $0, BoxLoop				#keeps drawing horizontal lines for the box as long as $s0 > 0
	
	lw $s0, 16($sp)					#restore $ra and $s0 and fix sp 
	lw $ra, 20($sp)
	addiu $sp, $sp, 24
	jr $ra
	
	
	
#Procedure to draw a large "black" box over the entire display

#no arguments no output

ClearDisp:
	addiu $sp, $sp, -4	
	sw $ra, 0($sp)					#save $ra
	li $a0, 0					#start @ 0,0 (a0 = 0, a1 = 0)
	li $a1, 0
	li $a2, 11					#black color (a2 = 11)
	li $a3, 64					#full screen size (a3 = 64)
			
	jal DrawBox					#calls the DrawBox function with the arguments listed above
	
	#restore ra, sp
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
	
	
#Procedure to draw the vertical and horizontal lines that make up the game board

# no arguments no output

DrawBoard:
	addiu $sp, $sp, -12				#create stack frame/save $ra and a regs
	li $a2, 13					#color white for lines
	li $a3, 64					#length of line 32
	sw $a2, 8($sp)
	sw $a3, 4($sp)
	sw $ra, 0($sp)
	li $a1, 15					#y coordinate for the start of the horizontal line 

	lineLoop:
	li $a0, 0					#x coordinate for start of horizontal line 
	jal HorzLine					#calls the horizontal line procedure with the args above
	lw $a3, 4($sp)
	addi $a1, $a1, 1
	li $a0, 0
	jal HorzLine
	addi $a1, $a1, 15				#horizontal lines spaced 15 coordinates apart from each other in the y direction
	lw $a3, 4($sp)
	blt $a1, 50, lineLoop
	
	li $a0, 15					#x coordinate for start of vertical line 

	vLineLoop:
	li $a1, 0					#y coordinate for the start of the vertical line 
	jal VertLine
	lw $a3, 4($sp)
	addi $a0, $a0, 1
	li $a1, 0
	jal VertLine
	addi $a0, $a0, 15				#vertical lines spaced 15 coordinate apart from each other in the x direction
	lw $a3, 4($sp)
	blt $a0, 50, vLineLoop

	
	lw $a2, 8($sp)					#restores a regs
	lw $a3, 4($sp)
	
	lw $ra, 0($sp)					#restore $ra and deallocate stack 
	addiu $sp, $sp, 12
	jr $ra


#Procedure DestroyTile blacks out the tile at the indicies given by $a0, $a1

#arguments $a0, $a1 hold the indicies of the column and row of the tile to be blacked out 

#returns nothing 
	
DestroyTile:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	sll $a0, $a0, 4
	sll $a1, $a1, 4
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	li $a2, 11
	li $a3, 14
	jal DrawBox
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	

#Procedure DrawTile draws a new tile on the board depending on the indicies provided in the arguments and the number to be drawn on the tile 

# args $a0 the column index of the new tile to be drawn 

#$a1 the row index of the new tile to be drawn

#$a2 the value to be drawn on the tile 

DrawTile:
	addi $sp, $sp, -60
	sw $s6, 56($sp)			#store temps and s regs since OutText will change nearly all the temp registers 
	sw $s7, 52($sp)
	sw $t2, 48($sp)
	sw $t3, 44($sp)
	sw $t4, 40($sp)
	sw $t5, 36($sp)
	sw $t6, 32($sp)
	sw $t7, 28($sp)
	sw $t8, 24($sp)
	sw $t9, 20($sp)
	sw $s2, 16($sp)
	sw $s1, 12($sp)
	sw $ra, 8($sp)
	add $s1, $0, $a2		#store the value to be drawn on the tile in $s1
	li $s2, -1
	redux:				#redux loop to determine the offset 
		srl $s1, $s1, 1
		addi $s2, $s2, 1	#$s2 holds the offset
		bgt $s1, 1, redux
	
	
	sll $a0, $a0, 4		#convert indicies to coordinates 
	sll $a1, $a1, 4
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	sw $a0, 4($sp)
	sw $a1, 0($sp)
	add $a2, $0, $s2 #color	#the s2 offset serves as the color argument 
	li $a3, 14		#default size to 14
	jal DrawBox		#draws the tile 
	
	lw $a1, 0($sp)
	lw $a0, 4($sp)
	blt $s2, 3, single	#determine if the number be be drawn on the tile is a single, double, triple, or quadruple digit number 
	blt $s2, 6, double
	blt $s2, 9, triple
	bge $s2, 9, quadOne
	
	single:
		blt $s2, 2, bLet
		j cTexts
		bLet:
		   li $s6, 4		#makes sure that the 2 and 4 have a black color to them 
		cTexts:
		addi $a0, $a0, 4	#makes sure to shift the coordinates to an appropriate position to draw the digit
		addi $a1, $a1, 4
		la $a2, Digits
		sll $t0, $s2, 1		#converts offset to actual offset
		add $a2, $a2, $t0	#adds to the address of the digits table 
		add $a3, $0, $s2	#background color determined by offset
		jal OutText
		li $s6, 0		#resets the coloration
		j endDraw
	double:
		addi $a0, $a0, 2	#makes sure to shift the coordinates to an appropriate position to draw the digit
		addi $a1, $a1, 4
		la $a2, Digits
		addi $a2, $a2, 6	#increments to the double digit numbers in the Digits table 
		subi $t0, $s2, 3	#converts offset to actual offset 
		mul $t0, $t0, 3
		add $a2, $a2, $t0	#adds to address
		add $a3, $0, $s2	#background color determined by offset
		jal OutText
		j endDraw
	triple:
		beq $s2, 6, noAdd	#makes sure that 128 is not shifted when drawn 
		addi $a0, $a0, 1
		noAdd:
		addi $a1, $a1, 4	#shifts coordinate to an appropriate position to draw the digit
		la $a2, Digits
		addi $a2, $a2, 15	#increments to the triple digit numbers in the Digits table
		subi $t0, $s2, 6	#converts offset to actual offset 
		sll $t0, $t0, 2
		add $a2, $a2, $t0	#adds to address
		add $a3, $0, $s2	#background color determined by offset
		jal OutText
		j endDraw
	quadOne:
	     li $s7, 0
	     beq $s2, 10, twenty	#determines whether to load the 1024 table or the 2048 table 
	     la $a2, thousandOne
	     j contQuad
	     twenty:
	     la $a2, thousandTwo
	     contQuad:
	     addi $a1, $a1, 4		#shifts the coordinate to an appropriate position to draw the digit 
	     sw $a1, 0($sp)
	     add $a3, $0, $s2		#puts $s2 into $a3 as the argument for background color in OutText
	     fLoop:
	     	lw $a1, 0($sp)		
	     	beq $s7, 0, setCol	#check counter for whether there should be a color change 
	     	beq $s7, 2, setCol
	     	li $s6, 12		
	     	j callText
	     	setCol:
	     		li $s6, 8	#alternate colors to allow for better visibility. I opted for 1024 and 2048 to be bluish. This is a divergence from the original game due to limitations
	     		j callText
	     	callText:
		jal OutText
		addi $s7, $s7, 1	#increments the counter 
		addi $a2, $a2, 2	#increment $a2 by two bytes to get next digit
		addi $a0, $a0, 3 	#moves the x coordinate by 3 
		blt $s7, 4, fLoop
	
	endDraw:
	lw $ra, 8($sp)			#restore
	lw $s1, 12($sp)
	lw $s2, 16($sp)
	lw $t9, 20($sp)
	lw $t8, 24($sp)
	lw $t7, 28($sp)
	lw $t6, 32($sp)
	lw $t5, 36($sp)
	lw $t4, 40($sp)
	lw $t3, 44($sp)
	lw $t2, 48($sp)
	lw $s7, 52($sp)
	sw $s6, 56($sp)
	addi $sp, $sp, 60
	jr $ra
	
	
	
	
# OutText: display ascii characters on the bit mapped display
#Arguments 
# $a0 = horizontal pixel co-ordinate (0-63)
# $a1 = vertical pixel co-ordinate (0-63)
# $a2 = pointer to asciiz text (to be displayed)
# $a3 = color value (0-7)
# $s6 = offset for color table 
#returns nothing 
OutText:
        addiu   $sp, $sp, -24
        sw      $ra, 20($sp)
        sw      $s6, 16($sp)

        li      $t8, 1          # line number in the digit array (1-12)
_text1:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2# 2     # assumes mars was configured as 64 x 64
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 8#10    # (a0 * 4) + (a1 * 4 * 64)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel

        move    $t2, $a2        # t2 = pointer to the text string
_text2:
        lb      $t0, 0($t2)     # character to be displayed
        addiu   $t2, $t2, 1     # last character is a null
        beq     $t0, $zero, _text9

        la      $t3, DigitTable # find the character in the table
_text3:
        lb      $t4, 0($t3)     # get an entry from the table
        beq     $t4, $t0, _text4
        beq     $t4, $zero, _text4
        addiu   $t3, $t3, 6    # go to the next entry in the table
        j       _text3
_text4:
        addu    $t3, $t3, $t8   # t8 is the line number
        lb      $t4, 0($t3)     # bit map to be displayed

        #sw      $zero, 0($t9)   # first pixel is black
        addiu   $t9, $t9, 4

        li      $t5, 3         # 8 bits to go out
_text5:
        #la      $t7, Colors
        #lw      $t7, 0($t7)     # assume black

        sll     $t0, $a3, 2	#use sll to convert color value to an offset
        la $t7, ColorTable	#loads address of color table
        add $t7, $t7, $t0	#adds that offset
	
        lw 	$t7, 0($t7)
        andi    $t6, $t4, 0x80  # mask out the bit (0=black, 1=white)
        beq     $t6, $zero, _text6
        la      $t7, Colors     # else it is black
        add     $t7, $t7, $s6   # add to the address of colors to get different colored numbers 
        #lw      $t7, 4($t7)
        lw      $t7, 0($t7)     # colored numbers 
_text6:
        sw      $t7, 0($t9)     # write the pixel color
        addiu   $t9, $t9, 4     # go to the next memory position
        sll     $t4, $t4, 1     # and line number
        addiu   $t5, $t5, -1    # and decrement down (8,7,...0)
        bne     $t5, $zero, _text5

       # sw      $zero, 0($t9)   # last pixel is black
        #addiu   $t9, $t9, 4
        j       _text2          # go get another character

_text9:
        addiu   $a1, $a1, 1     # advance to the next line
        addiu   $t8, $t8, 1     # increment the digit array offset (1-12)
        bne     $t8, 6, _text1

	lw      $s6, 16($sp)
        lw      $ra, 20($sp)
        addiu   $sp, $sp, 24
        jr      $ra
