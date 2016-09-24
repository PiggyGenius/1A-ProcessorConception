.data
.text
    xor $1,$1,$1
    ori $1,$1,15
    xor $2,$2,$2
    ori $1,$1,20
    addi $28,$zero,4
    slt $28,$1,$20
loop:
    j loop
