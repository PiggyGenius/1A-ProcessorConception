.text
loop:
    xor $28,$28,$28
    xor $1,$1,$1
    addi $1,$1,10
    j loop2
loop2:
    add $28,$28,1
    j loop2
fin:
    
    
# max_cycle 50
# pout_start
# 12340000
# ABCD0000
# pout_end
