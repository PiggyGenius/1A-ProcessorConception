.data
var: .word 666
.text
    xor $28,$28,$28
    ori $28,$28,66
    lw $28,var
loop:
    j loop
