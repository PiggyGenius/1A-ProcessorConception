.text
loop:
    xor $28,$28,$28
    xor $1,$1,$1
    jal loop2
loop2:
    or $28,$1,$31
    j loop2
fin:
    
    
# max_cycle 50
# pout_start
# 12340000
# ABCD0000
# pout_end
