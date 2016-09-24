.text
    xor $28, $28, $28
    addi $28, $28, 16
loop:
    addi $28,$28,-1
    bgez $28,loop
fin:
    j fin

# max_cycle 50
# pout_start
# 00000005
# 00000007
# pout_end
