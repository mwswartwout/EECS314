.data
promptED: .asciiz "\nWhat do you want to do with the file?\n0: Encryption\n1:Decryption\n... "
promptE: .asciiz "Enter the encryption key.\n"
promptM: .asciiz "Enter the modulus.\n"
promptExit: .asciiz "\nWould you like to exit?\n0: Decrypt/Encrypt another file.\n1: Exit.\n..."
promptFN:	.asciiz	"Enter the file name you wish to input: "
fname:	.asciiz	"C:\\Users\\Public\\rsa.txt"	# file name to read
fout:   .asciiz "C:\\Users\\Public\\rsa.txt"      # filename for output
promptC: .asciiz "Enter a shift number: "
output: .space 15
input:	.space 15 # location for input from file
#actual start of the main program
.text
.globl main
main:				#main has to be a global label

	#RSA numbers: Modulus = 143, encryption key = 7, decryption key = 103
	jal encryptOrDecrypt
	#beqz $s0, encrypt
	#jal getFileName	#Not working right now
	jal getModulus
	jal getExponent
	jal readFile
	#jal testPrintInput
	jal rsaMath
	#jal testPrintOutput

	#jal shiftCypherD
	jal writeFile
	jal exit		
	#beq	$s0, $0, Encrypt
	#j Decrypt

#encrypt:
#	jal readFile
#	jal shiftCypherE
#	jal writeFile
#	jal exit

encryptOrDecrypt:
	la	$a0, promptED	#prompt for encrypt or decrypt
	li	$v0,4
	syscall
	
	li	$v0, 5
	syscall
	add $s0, $v0, $zero	#save user input to register s0(0:e, 1:d)
	
	jr $ra

#getFileName:
#	# get file name from user
#	li	$v0, 4		# prompt user for file name to read
#	la	$a0, promptFN
#	syscall
#	
#	li	$v0, 8		# retrieve user input
#	la	$a0, fname	# location to store string
#	li	$a1, 100	# max number of characters
#	syscall
#
#	jr	$ra		# return to main method
		
getModulus:
	la $a0, promptM
	li $v0, 4
	syscall

	li $v0, 7
	syscall
	mov.d $f2, $f0	#modulus stored in f0 is moved to f2
	
	jr $ra
	
getExponent:
	la $a0, promptE
	li $v0, 4
	syscall

	li $v0, 5
	syscall
	add $s2, $v0, $zero	#encryption key in $s7 ($s7 = e)

	jr $ra	

readFile:	
	li   	$v0, 13       	# system call for open file
 	la   	$a0, fname   	# output file name
  	li   	$a1, 0       	# Open for reading (flags are 0: read, 1: write)
  	li   	$a2, 0       	# mode is ignored
  	syscall            	# open a file (file descriptor returned in $v0)

  	add 	$s6, $v0, $zero     	# save the file descriptor 
  
 	# read from file just opened
 	li   	$v0, 14      	# system call for read from file
  	add 	$a0, $s6, $zero     	# file descriptor 
  	la   	$a1, input  	# address to store text from file
  	li   	$a2, 15      # hardcoded buffer length
  	syscall           	# read file
  	
 	# Close the file 
  	li   	$v0, 16      	# system call for close file
  	add 	$a0, $s6, $zero     	# file descriptor to close
  	syscall          	# close file

	#jal	Test_Print	#NEED TO SAVE ADDRESS TO DIFFERENT REGISTER!!!
	#jal	Test_Change	#Test functions commented out

	jr $ra

#testPrintInput:
#	la	$a0, input
#	li	$v0, 4
#	syscall
#
#	jr $ra
	
#testPrintOutput:
#	la	$a0, output
#	li	$v0, 4
#	syscall
#	
#	jr $ra

#testPrintChar:
#	la	$a0, ($t4)
#	li	$v0, 4
#	syscall
#	
#	jr $ra

#testChange:
#	li	$v0, 4
#	la	$t0, input
	
#printLoop:
#	lb	$t2, ($t0)
#	beqz	$t2, JReturn
#	#jal	encrChar
#	sb	$t2, ($t0)
#	addi	$t0, $t0, 1
#	j	printLoop

#JReturn:
#	la	$a0, input
#	syscall
#	
#	jr	$ra
	
rsaMath:
	move $s3, $ra 	#saves the return address into s3 because a jal is called later in powerE
	la $t0, input	#puts address of input into $t0
	la $t4, output #puts address of output into $t4
	addi $t0, $t0, -1 #decrements t0 so that the first loop of iterateCharacters does not skip the first character in the file
	addi $t4, $t4, -1 #decrements t4 so that the first loop of iterateCharacter writes the initial garbage to a wrong location
#	addi $t8, $t8, 32767
#	mtc1.d $t8, $f4
#	cvt.d.w $f4, $f4
	
iterateCharacters:
	move $t1, $s2		#copies exponent into $t1
	#jal testPrintChar
	cvt.w.d $f6, $f6 	#converts the working value (f6) from a double-precision floating point to an integer
	mfc1 $t2, $f6 		#moves the new integer value in f6 to t2
	sb $t2, ($t4) 		#stores the value of t2 in t4
	addi $t4, $t4, 1 	#increments t4 so that the output location stays up-to-date
	addi $t0, $t0, 1 	#increments t0 so that the next char is read from the input
	lb $t2, ($t0)		#loads current character into t2
	mtc1 $t2, $f6 		#moves the current char from t2 into f6
	cvt.d.w $f6, $f6 	#converts the value in f6 from an integer to a double precision floating point
	
	mov.d $f8, $f6 		#makes a copy of the original char, for use in powerE
	beqz $t2, exitRsaMath 	#if the most recent char that has been read is zero, then the EOF has been reached, and exits encryption
	
powerE:	
	beq $t1, 1, modN	#if the power remaining = 1, take the mod
	mul.d $f6, $f6, $f8	#multiply current char by original char
	jal modN
	addi $t1, $t1, -1	#decrement $t1
	bgt $t1, 1, powerE	#branch to top of loop if not fininshed
	j iterateCharacters

modN:
	div.d $f6, $f6, $f2	#divide the working value (f6) by the modulus (f2)
	trunc.w.d $f10, $f6	#truncate the working value (f6) and store in f10 (2.xxxxx -> 2)
	cvt.d.w $f10, $f10	#converts the truncated floating point value to an integer
	sub.d $f6, $f6, $f10	#subtracts working value (f6) - truncated value (f10) and stores in f6 (2.xxxxx - 2 = .xxxxx)
	mul.d $f6, $f6, $f2	#sets working value equal to remainder of division by multiplying decimal value (f6) by the modulus (f2)
	round.w.d $f6, $f6	#rounds the working value in case there is a slight error in the division/multiplication
	cvt.d.w $f6, $f6	#converts the integer now in f6 to a double precision floating point
#	c.lt.d $f6, $f4
#	bc1t modI
#	sub.d $f6, $f6, $f2
#	j modN
	#slt $t3, $t2, $s1	#if working value < n, t3 = 1
	#bne $t3, $0, iterateCharacters		#exit loop (loop performs mod n)
	#sub $t2, $t2, $s1	#subtract n from the working value
	jr $ra

#modI:
#	cvt.w.d $f6, $f6
#	mfc1 $t9, $f6
#	cvt.w.d $f2, $f2
#	mfc1 $s7, $f2
#	div $t9, $s7
#	mfhi $t2
#	j iterateCharacters

exitRsaMath:
	jr $s3
	
writeFile: # Create and open a new .txt file
	li   $v0, 13       # system call for open file
	la   $a0, fout     # address of output file name
	li   $a1, 1        # Open for writing flags 1 for write
	li   $a2, 0        # mode is ignored
	syscall            # open a file (file descriptor returned in $v0)
	add $s6, $v0, $zero      # save the file descriptor 

	# Write to file just opened
	li   $v0, 15       # system call for write to file
	move $a0, $s6      # file descriptor 
	la   $a1, output   # address of buffer from which to write
	li   $a2, 15     # hardcoded buffer length=1000
	syscall            # write to file

	# Close the file 
	li   $v0, 16       # system call for close file
	add $a0, $s6, $zero      # file descriptor to close
	syscall            # close file

	jr $ra

#shiftCypherE:
#	la $a0, promptC
#	li $v0, 4
#	syscall
#
#	li $v0, 5
#	syscall
#	add $s2, $v0, $zero	
#	
#	la $t0, input	#puts address of input into $t0
#	la $t4, output #puts address of output into $t4

#shiftE:
#	lb $t2, ($t0)
#	beqz $t2, rtm
#	add $t2, $t2, $s2
#	sb $t2, ($t4)
#	addi $t0, $t0, 1
#	addi $t4, $t4, 1
#	j shiftE

#shiftCypherD:
#	la $a0, promptC
#	li $v0, 4
#	syscall
#
#	li $v0, 5
#	syscall
#	add $s2, $v0, $zero	
#	
#	la $t0, input	#puts address of input into $t0
#	la $t4, output #puts address of output into $t4

#shiftD:
#	lb $t2, ($t0)
#	beqz $t2, rtm
#	sub $t2, $t2, $s2
#	sb $t2, ($t4)
#	addi $t0, $t0, 1
#	addi $t4, $t4, 1
#	j shiftD

#rtm:
#	jr $ra
	
exit:	
	la $a0, promptExit
	li $v0, 4
	syscall

	li $v0, 5
	syscall
	add $s0, $v0, $0

	beq $v0, $0, main

	li $v0, 10
	syscall
