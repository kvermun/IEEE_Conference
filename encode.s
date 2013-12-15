#################### DATA SEGMENT ####################
.data
fin:   .asciiz "D:/original.txt"
mout:	.asciiz "D:/post_encoding.txt"
spac:   .asciiz " : " 
newline:   .asciiz "\n" 
end:   .asciiz "Completed\n" 
peak_msg: .asciiz "Peak is:"
i_prompt: .asciiz "Enter string:"
buffer: .space 4	#buffer for reading a file
rbuffer: .space 4   #buffer for reading the file while updating
tinput: .space 180 	#buffer for user input
wbuffer: .space 4 	#buffer for writing the file while updating
#################### CODE SEGMENT ####################
		.text
		.globl main
main:
	#opening input file
	li   $v0, 13
	la   $a0, fin
	li   $a1, 0
	li   $a2, 0
	syscall 
	# s6 stores fin FILE DESCRIPTOR
	move $s6,$v0
	# reading from file


add $sp,$sp,-4
move $s7,$sp 	# $s7 stores the base stack pointer
li $t1,3
li $t3,0 		# final number to be stored
li $t4,10 		#contant
li $t5,4 		#constant
li $t7,0 		#number stored in peak 
li $t8,0 		#peak
li $t9,0  		# temp variable used in loop

# loop for reading from file and processing
readLoop:
# read from file and store in buffer
li   $v0, 14
move $a0, $s6
la   $a1, buffer
li   $a2, 4 
syscall
# loading data from buffer for converting to integer
la $t0,buffer

loop:
	#current byte stored in $t2
	lb $t2,($t0)
	beq $t2,0x20,storeAndContinue 	# checking if space has occured

	beq $t2,0xD,checkEmpty
	beq $t2,0x0,checkEmpty
	beq $t2,0xA,checkEmpty
	addi $t2,$t2,-48

	mul $t3,$t3,$t4
	add $t3,$t3,$t2
	add $t0,$t0,1
	b loop
storeAndContinue:

	move $t9,$t3
	mul $t3,$t3,$t5
	sub $sp,$sp,$t3
	lw $t6,($sp)
	addi $t6,$t6,1
	bgt $t6,$t7,setMax
	ret:
	sw $t6,($sp)
	li $t3,0
	add $t0,$t0,1
	move $sp,$s7

b readLoop
# assigning max values
setMax:
move $t7,$t6
move $t8,$t9

b ret

#check if 255 pixel is empty
checkEmpty:
	# printing peak obtained
	la $a0,peak_msg
	li $v0,4
	syscall
	move $a0,$t8
	li $v0,1
	syscall
	la $a0,newline
	li $v0,4
	syscall
	# cheking is pixel 255 has zero count
	li $s1,255
	li $s2,1024
	move $sp,$s7
	sub $sp,$sp,$s2
	lw $s3,($sp)
	beqz $s3,takeinput
	b exit 			# exiting if 255 is not empty

closefile:
li   $v0, 16
move $a0, $s6
syscall 

########## Encoding string to file ##############

move $sp,$s7
sub $sp,$sp,$s2

# input stored in tinput buffer
takeinput:
	la $a0,i_prompt
	li $v0,4
	syscall
	la $a0,tinput
	li $a1,20
	li $v0,8
	syscall
	la $s3,tinput
	li $s0,8
	lb $t1,($s3)
	beqz $t1,exit
	add $s3,$s3,1
#ecoding started
encode:

	openfile:
	#opening file to write
	li   $v0, 13
	la   $a0, mout
	li   $a1, 1
	li   $a2, 0
	syscall 
	# saving FILE DESCRIPTOR to $s7(Earlier storing stack base pointer-Not Required now)
	move $s7,$v0

	li   $v0, 13
	la   $a0, fin
	li   $a1, 0
	li   $a2, 0
	syscall 
	# reading FILE DESCRIPTOR to $s6
	move $s6,$v0
	# reading 4 byte once


	#constants
	li $t3,0
	li $t4,10

#convert ascii tread from file to number
convNumber:
	li   $v0, 14
	move $a0, $s6
	la   $a1, rbuffer
	li   $a2, 4 
	syscall
	la $t0,rbuffer
	li $t3,0
repeatp:
	lb $t2,($t0)
	beq $t2,0x20,checkAndReturn
	beq $t2,0xD,checkAndReturn
	beq $t2,0x0,checkAndReturn
	beq $t2,0xA,checkAndReturn
	addi $t2,$t2,-48
	mul $t3,$t3,$t4
	add $t3,$t3,$t2
	add $t0,$t0,1
	b repeatp

checkAndReturn:
	
	beq $t3,$t8,cPeak
	bgt $t3,$t8,incAndWrite
	blt $t3,$t8,writeToFile


# if greater than peak then directly increase
incAndWrite:
	addi $t3,$t3,1
	b writeToFile


#if equal to peak then check input string for next bit
checkAndWrite:
	li $s0,8
	lb $t1,($s3)
	add $s3,$s3,1                                                                
	

cPeak:
	beqz $t1,writeToFile
	beqz $s0,checkAndWrite
	and $s8,$t1,0x80
	addi $s0,$s0,-1
	sll $t1,$t1,1
	beq $s8,0x80,incAndWrite
	beq $s8,0x00,writeToFile
	beqz $t1,writeToFile
	b cPeak
	b writeToFile
# writing number to file after converting to character
# $t3 is the integer always written to file
# a character is also being added at the end
writeToFile:
	
	li $s4,0
	sb $s4,($sp)
	sub $sp,$sp,1
	sb $t2,($sp)
	sub $sp,$sp,1	
	li $s4,3
	li $t6,10

extractDigit:
	beqz $s4,writeNumber
	div $t9,$t3,$t6
	move $t5,$t9
	mul $t9,$t9,$t6
	sub $t9,$t3,$t9
	addi,$t9,$t9,48
	sb $t9,($sp)
	sub $sp,$sp,1	
	addi $s4,$s4,-1
	move $t3,$t5
	b extractDigit


writeNumber:
# writing the number calculated
	add $sp,$sp,1
	li   $v0, 15
	move $a0, $s7
	move $a1,$sp
	li   $a2, 4
	syscall
	add $sp,$sp,4
# exit if EOF is reached
	beq $t2,0xD,exit
	beq $t2,0x0,exit
	beq $t2,0xA,exit


	add $t0,$t0,1 	#moving pointer to the next bit in buffer
	li $t3,0 		#reset integer to 0 

	b convNumber



# exiting
exit:
#closing read file
li   $v0, 16
move $a0, $s6
syscall 
# closing output file
li   $v0, 16
move $a0, $s7
syscall 
# print completion message
la $a0,end
li $v0,4
syscall
#exiting gracefully
li $v0,10
syscall