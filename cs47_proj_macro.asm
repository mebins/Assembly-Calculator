# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#

#reg d is the mask

#regs is the source
#regT is position
.macro extract_nth_bit($regD,$regS,$regT)
li $regD, 0x1 #Extract 
sllv $regD, $regD,$regT
and $regD, $regS,$regD 
srlv $regD, $regD,$regT 
.end_macro

#regs is the source
#reg d is the mask
#regT is position
.macro extract_nth_bit_d($regD,$regS,$regT)
li $regD, 0x1 #Extract 
sll $regD, $regD,$regT
and $regD, $regS,$regD 
srl $regD, $regD,$regT 
.end_macro


#regD is Bit pattern
#regS is the Position
#regT is the 0x0 0x1
#maskReg is temporary mask
.macro insert_to_nth_bit($regD,$regS,$regT,$maskReg)
li $maskReg, 0x1 #INSERT
sllv $maskReg, $maskReg,$regS
not $maskReg,$maskReg
and $regD,$regD,$maskReg
sllv $regT, $regT, $regS
or $regD,$regT,$regD
srlv $regT,$regT,$regS
.end_macro
