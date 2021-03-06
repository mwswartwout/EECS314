#Data section contains prompts, file location, and input and output spaces
.data
promptED: 	.asciiz 	"\nWhat do you want to do with the file?\n0: Encryption\n1:Decryption\n... "
promptE: 	.asciiz 	"Enter the key (exponent).\n"
promptM: 	.asciiz 	"Enter the modulus. The modulus cannot be greater than 255\n"
promptExit:	.asciiz 	"\nWould you like to exit?\n0: Decrypt/Encrypt another file.\n1: Exit.\n..."

fname:		.asciiz		"C:\\Users\\Public\\rsa.txt"	# file name to read
fout:   	.asciiz 	"C:\\Users\\Public\\rsa.txt"	# filename for output

output: 	.space 		52	#location for output to file
input:		.space 		52	# location for input from file

#Begin code
.text
.globl main
main:				
	#Modulus can be no greater than 255
	#Suggested RSA numbers: [Modulus = 129, encryption key = 5, decryption key = 17]
	jal encryptOrDecrypt
	jal getModulus
	jal getExponent
	jal readFile
	jal rsaMath
	jal writeFile
	jal exit		

encryptOrDecrypt:
	la	$a0, promptED	#prompt for encrypt or decrypt
	li	$v0,4		#syscall value for print string is 4
	syscall
	
	li	$v0, 5		#syscall value for read integer is 5
	syscall
	add $s0, $v0, $zero	#save user input to register s0 (0=encrypt, 1=decrypt)
	
	jr $ra

#Prompts the user to enter the modulus
getModulus:
	la $a0, promptM		#Loads the prompt to enter the modulus
	li $v0, 4
	syscall

	li $v0, 5
	syscall
	move $s7, $v0		#modulus is store
	
	jr $ra

#Prompts the user to enter the exponent
getExponent:
	la $a0, promptE		#Loads the prompt to enter the exponent
	li $v0, 4
	syscall

	li $v0, 5
	syscall
	add $s2, $v0, $zero	#exponent is stored in s2

	jr $ra	

#Reads the contents of the file into memory
readFile:	
	li   	$v0, 13       	# system call for open file
 	la   	$a0, fname   	# output file name
  	li   	$a1, 0       	# Open for reading (flags are 0: read, 1: write)
  	li   	$a2, 0       	# mode is ignored
  	syscall            	# open a file (file descriptor returned in $v0)

  	add 	$s6, $v0, $zero	# save the file descriptor 
  
 	# read from file just opened
 	li   	$v0, 14      	# system call for read from file
  	add 	$a0, $s6, $zero # file descriptor 
  	la   	$a1, input  	# address to store text from file
  	li   	$a2, 52      	# hardcoded buffer length
  	syscall           	# read file
  	
 	# Close the file 
  	li   	$v0, 16      	# system call for close file
  	add 	$a0, $s6, $zero # file descriptor to close
  	syscall          	# close file

	jr $ra
	
#Begins the RSA character manipulation math
rsaMath:
	move $s3, $ra		#saves the return address into s3 because a jal is called later in powerE
	la $t0, input		#puts address of input into $t0
	la $t4, output 		#puts address of output into $t4
	addi $t0, $t0, -1 	#decrements t0 so that the first loop of iterateCharacters does not skip the first character in the file
	addi $t4, $t4, -1 	#decrements t4 so that the first loop of iterateCharacter writes the initial garbage to a wrong location

#Loop that iterates through each character
iterateCharacters:
	move $t1, $s2		#copies exponent into $t1
	sb $t2, ($t4) 		#stores the value of t2 in t4
	addi $t4, $t4, 1 	#increments t4 so that the output location stays up-to-date
	addi $t0, $t0, 1 	#increments t0 so that the next char is read from the input
	lb $t2, ($t0)		#loads current character into t2
	move $t3, $t2		#makes a copy of the original char, for use in powerE
	
	beqz $t2, exitRsaMath 	#if the most recent char that has been read is zero, then the EOF has been reached, and exits encryption

#Loop that iterates through taking each character to the proper power	
powerE:	
	beq $t1, 1, modN	#if the power remaining = 1, take the mod
	mult $t2, $t3		#multiply current char by original char
	mflo $t2
	jal modN
	addi $t1, $t1, -1	#decrement $t1
	bgt $t1, 1, powerE	#branch to top of loop if not fininshed
	j iterateCharacters

#Takes the modulus of the working value in f6
modN:
	div $t2, $s7		#divide the working value (t2) by the modulus (s7)
	mfhi $t2		#retrieve the remainer from HI and set as working value

	jr $ra

#Exits the rsaMath loop 
exitRsaMath:
	jr $s3
	
#Writes the new text to the file
writeFile:
	li   $v0, 13       	# system call for open file
	la   $a0, fout     	# address of output file name
	li   $a1, 1        	# Open for writing flags 1 for write
	li   $a2, 0        	# mode is ignored
	syscall            	# open a file (file descriptor returned in $v0)
	add $s6, $v0, $zero     # save the file descriptor 

	# Write to file just opened
	li   $v0, 15       	# system call for write to file
	move $a0, $s6      	# file descriptor 
	la   $a1, output   	# address of buffer from which to write
	li   $a2, 52     	# hardcoded buffer length=1000
	syscall            	# write to file

	# Close the file 
	li   $v0, 16       	# system call for close file
	add $a0, $s6, $zero     # file descriptor to close
	syscall            	# close file

	jr $ra

#User decides whether to terminate the program, or restart
exit:	
	la $a0, promptExit	#Loads exit prompt
	li $v0, 4
	syscall

	li $v0, 5
	syscall

	beq $v0, $0, main	#If user enters 0, restarts program

	li $v0, 10		#else quit
	syscall
