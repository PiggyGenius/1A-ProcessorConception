xor $1,$1,$1
addi $1,$1,-2
bgezal $1,loop
j loop2
loop:
    or $28,$zero,$31
    j loop
loop2:
    addi $28,$28,1
    j loop2
