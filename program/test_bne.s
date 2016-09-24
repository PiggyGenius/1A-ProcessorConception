.text
    xor $3, $3, $3
    xor $4, $4, $4
    addi $4, $4, 30
    addi $3, $3, 16
    j loop2
loop2:
    addi $28, $28, 1
    bne $28, $3, loop2
loop3:
    addi $28, $28, 2
    bne $28, $4, loop3
fin:
    j fin

# max_cycle 50
# pout_start
# 00000005
# 00000007
# pout_end
