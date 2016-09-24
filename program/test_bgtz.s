.text
xor $1,$1,$1
addi $1,$1,-10
bgtz $1, loop
j loop2

loop:
    j loop
loop2:
    addi $28,$zero,1
    j loop2


# max_cycle 50
# pout_start
# 00000005
# 00000007
# pout_end
