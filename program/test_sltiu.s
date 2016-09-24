xor $1,$1,$1
addi $1,$1,-10
xor $2,$2,$2
addi $2,$2,5

addi $28,$28,2
sltiu $28,$1,9
loop:
    j loop
