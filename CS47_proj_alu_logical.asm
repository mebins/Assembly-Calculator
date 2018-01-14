.include "./cs47_proj_macro.asm"
.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 24
	
	operation_check:
	
	beq $a2, '+', add_logical
	beq $a2, '-', sub_logical
	beq $a2, '*', mul_logical
	beq $a2, '/', div_logical
	
	add_logical:
	li $a2, 0x0
	j add_sub_logical
	
	sub_logical:
	li $a2, 0xFFFFFFFF
	
	add_sub_logical:
	#t0 - COUNTER
	#t1 - A
	#t2 - B
	#t8 - CARRY IN CARRY OUT
	#t9 - SUM
	li $t0, 0
	li $v0, 0 
	li $t9, 0 
	
	
	extract_nth_bit_d($t8,$a2,0) # SIGNAL 
	beqz $t8, add_mode
	
	sub_mode:
	not $a1,$a1
	add_mode:
	#t3 A XOR B
	#t4 A AND B
	#t5, TEMP MASK
	#t6 CI AND (A XOR B)
	#t8 CI AND (A XOR B) + (A AND B) << COUNTER
	#t9 CI XOR (A XOR B) << SUM
	extract_nth_bit($t1,$a0,$t0) # A
	extract_nth_bit($t2,$a1,$t0) # B
	xor $t3, $t1,$t2 # A XOR B
	and $t4, $t1,$t2 # A AND B
	and $t6, $t8, $t3 # CI AND (A XOR B)
	xor $t9, $t3, $t8 # CI XOR (A XOR B) << SUM
	or $t8, $t6, $t4 # CI AND (A XOR B) + (A AND B) << COUT
	
	insert_to_nth_bit($v0,$t0,$t9,$t5)
	add $t0,$t0,1
	blt $t0,32,add_mode
	move $v1,$t8 #LAST Co in $v1
	add_mode_end:
	j au_logical_end
	
	mul_logical:
	jal mul_signed
	j au_logical_end
	
	div_logical:
	jal div_signed
	au_logical_end:
	
	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	
	jr 	$ra

#####################################################################
# Implement twos_complement
# Argument:
# 	$a0: Number of which 2's complement to be computed
# Return:
#	$v0: Two's complement of $a0
# Notes:
#####################################################################
twos_complement:
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1, 8($sp)
	addi 	$fp, $sp, 20

	not $a0,$a0
	li $a1, 1
	li $a2, '+'
	jal au_logical
	
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1, 8($sp)
	addi	$sp, $sp, 20
jr $ra

#####################################################################
# Implement twos_complement_if_neg
# Argument:
# 	$a0: Number of which 2's complement to be computed
# Return:
#	$v0: Two's complement of $a0 of $a0 is negative
# Notes:
#####################################################################
twos_complement_if_neg:
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1, 8($sp)
	addi 	$fp, $sp, 20

	bgez $a0,positive
	
	jal twos_complement
	j twos_complement_if_neg_end
	positive:
	move $v0,$a0
	twos_complement_if_neg_end:
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1, 8($sp)
	addi	$sp, $sp, 20
jr $ra

#####################################################################
# Implement twos_complement_64bit
# Argument:
# 	$a0: Lo of the number
	#$a1: Hi of the number
# Return:
#	$v0: Lo part of 2's complemented 64 bit
#	$v1: Hi part of 2's complemented 64 bit
# Notes:
#####################################################################
twos_complement_64bit:
	#t0 is a0
	#t1 is a1
	#a0 is first number 
	#a1 is second number
	#a2 operation +
	
	addi	$sp, $sp, -28
	sw	$fp, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw 	$a2, 12($sp)
	sw  	$s1, 8($sp)
	addi $fp, $sp, 28
	
	move $s1,$a1 #keep hold of arg 2
	not $a0,$a0 #inverse arg 1 
	li $a2, '+' #set operation command to add
	li $a1, 1 # change a1 to 1 to add 1
	jal au_logical #~arg1 + 1 = $v0
	move $a1,$v1 #move the carry out of ~arg1 + 1 to $a1
	move $a0,$s1 #copy the value of arg2 to $a0
	not $a0,$a0 #inverse arg 2
	move $s1,$v0 #copy the ~arg1+1 to $s1
	jal au_logical # ~arg2 + carryout 
	move $v1,$v0 #move addition of ~arg2 + carryout to $v1
	move $v0,$s1 #move ~arg1+1 to $v0
	
	lw	$fp, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw 	$a2, 12($sp)
	lw  	$s1, 8($sp)
	addi	$sp, $sp, 28
jr $ra

#####################################################################
# Implement bit_replicator
# Argument:
# 	$a0: 0x0 or 0x1 (the bit value to be replicated)
# Return:
#	$v0: 0x0 if $a0 = 0x0 or 0xFFFFFFFFF if $a0 = 0x1
# Notes:
#####################################################################
bit_replicator:
	
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0, 8($sp)
	addi	$fp, $sp, 16
		beqz $a0,bit_replicator_zero
		
		bit_replicator_one:
		li $v0, 0xFFFFFFFF
		j bit_replicator_end
		
		bit_replicator_zero:
		li $v0, 0x00000000
		bit_replicator_end:
		
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0, 8($sp)
	addi	$sp, $sp, 16
jr $ra

#####################################################################
# Implement mul_unsigned
# Argument:
# 	$a0: Multiplicand
#	$a1: Multiplier

# Return:
#	$v0: Lo part of result
#	$v1: Hi Part of the result
# Notes:
#####################################################################
mul_unsigned:
	
	addi	$sp, $sp, -32
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi	$fp, $sp, 32

	
	#a0 Multiplicand
	#a1 Multiplier
	
	#$t1 left most bit of multiplier
	#$t2 and of left most bit of multiplier and multiplicand
	li $s0, 0 #counter i = 0
	li $v1, 0 #H = 0
	move $v0, $a1 #move multiplier into lo register L = MLPR
	#A0 - M = MCND
	mul_loop:
	extract_nth_bit($t1,$v0,$zero)
	move $s1, $v0 
	move $s2, $a0
	move $a0,$t1
	jal bit_replicator # R = {32{L[0]}}
	move $t1,$v0
	move $v0,$s1
	move $a0,$s2
	 
	and $t2,$t1,$a0 #index of lsb with $a0 X = M & R
	
	move $s1, $v0 #stores lo
	move $s2, $a0 #stores multiplicand
	
	move $a0, $v1 # argument for au logical - product
	move $a1, $t2 # argument for au logical - 0 or 1
	li $a2, '+'
	jal au_logical # H = H+X		
	#v0 product + t2 
	move $v1, $v0 # moving product back to product register
	move $v0,$s1  # moving lo back to lo register
	move $a0,$s2  # moving back multiplicand
	
	#regD is Bit pattern
	#$t6 first bit of Product
	#t5 is 31 value
	#t7 is temp mask
	srl $v0,$v0,1 #L = L >> 1
	li $t5, 31 
	extract_nth_bit_d($t6,$v1,0) #H[0]
	insert_to_nth_bit($v0,$t5,$t6,$t7)#L[31] = H[0]
	srl $v1,$v1,1 # H = H >> 1
	addi $s0, $s0,1 #I = I +1
	blt $s0, 32, mul_loop
	mul_loop_end:
	
		
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 32
jr $ra

#####################################################################
# Implement mul_signed
# Argument:
# 	$a0: Multiplicand
#	$a1: Multiplier

# Return:
#	$v0: Lo part of result
#	$v1: Hi Part of the result
# Notes:
#####################################################################
mul_signed:
	
	addi	$sp, $sp, -32
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi 	$fp, $sp, 32
	
	move $s1,$a0
	move $s2,$a1
	
	jal twos_complement_if_neg
	move $s0, $v0
	move $a0, $a1
	
	jal twos_complement_if_neg
	move $a1,$v0
	move $a0,$s0
	
	jal mul_unsigned
	
	extract_nth_bit_d($t0,$s1,31)
	extract_nth_bit_d($t1,$s2,31)
	move $a0,$v0
	move $a1,$v1
	xor $t0,$t0,$t1
	beqz $t0,mul_signed_restore
	jal twos_complement_64bit
	mul_signed_restore:
	
		
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 32
jr $ra

#####################################################################
# Implement div_unsigned
# Argument:
# 	$a0: Dividend
#	$a1: Divisor

# Return:
#	$v0: Quotient
#	$v1: Remainder
# Notes:
#####################################################################
div_unsigned:
	
	addi	$sp, $sp, -32
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi	$fp, $sp, 32
	
	#s0 is counter
	#s1 is remainder
	#s2 is quotient
	
	li $s0, 0 # I = 0
	li $s1, 0 # R = 0
	move $s2, $a0 # Q = DVND
	#a1 = D - DVSR 

	div_loop:
	
	sll $s1,$s1,1 # R = R << 1
	extract_nth_bit_d($t0,$s2,31) # Q[31]
	insert_to_nth_bit($s1,$zero,$t0,$t9) #R[0] = Q[31]
	sll $s2,$s2,1 #Q = Q << 1
	move $a0, $s1 # a0 = R
	#a1 = D
	li $a2, '-'
	jal au_logical #S = R - D
	bltz $v0, div_increment # S < 0
	move $s1, $v0 # R = S 
	li $t0, 1
	insert_to_nth_bit($s2,$zero,$t0,$t9) # Q[0] = 1

	div_increment:
	addi $s0,$s0,1 # i = i+1
	blt $s0,32,div_loop # i == 32
	move $v0, $s2
	move $v1, $s1
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 32
jr $ra

#####################################################################
# Implement div_signed
# Argument:
# 	$a0: Dividend
#	$a1: Divisor

# Return:
#	$v0: Quotient
#	$v1: Remainder
# Notes:
#####################################################################
div_signed:
	
	addi	$sp, $sp, -40
	sw	$fp, 40($sp)
	sw 	$s4, 36($sp)
	sw	$s3, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi 	$fp, $sp, 40
	
	#s0 - A0 
	#s1 - A1 
	move $s0,$a0
	move $s1,$a1
	
	
	jal twos_complement_if_neg  # Make N1 Positive
	move $s2,$v0 #N1 is in T0
	move $a0,$a1 
	jal twos_complement_if_neg # Make N2 Positive
	move $a1,$v0 
	move $a0,$s2 
	
	jal div_unsigned #DIV OF N1 N2 return to V0 V1
	move $a0, $v0 #Q
	move $s3, $v0 #Q
	move $a1, $v1 #R
	move $s4,$v1 #R
	
	extract_nth_bit_d($t0,$s0,31) # Extract A0[31]
	extract_nth_bit_d($t1,$s1,31) # Extract A1[31]
	
	xor $t2,$t1,$t0 # A1[31] XOR A0[31]
	
	move $s2,$t0 #A0[31]
	
	beqz $t2,tc_q_end #If S is 1 two complement Q
	
	move $a0,$s3
	jal twos_complement
	move $s3, $v0
	tc_q_end:
	
	beqz $s2,tc_r_end #If S is 1 two complement Q
	
	move $a0,$s4
	jal twos_complement
	move $s4, $v0
	tc_r_end:
	move $v0,$s3
	move $v1,$s4
	
	lw	$fp, 40($sp)
	lw 	$s4, 36($sp)
	lw	$s3, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	
	addi	$sp, $sp, 40
jr $ra




