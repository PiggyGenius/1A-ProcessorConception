.text
# Le motif du chenillard (2 bits consécutifs) est mis dans $1
# Le chenillard est sur 4 LED
ori $1,$0,0x03
boucle_infinie:
   li $2, 10000000
boucle_attente:
   addi $2, $2, -1
   bne $2, $0, boucle_attente
# On affiche le motif
   ori $28, $1, 0
# On décale le motif
   sll $1, $1, 1
# On cherche un dépassement en dehors des 4 LED
   andi $2, $1, 0x10
   beq $2, $0, boucle_infinie
#En cas de changement, on ramène la LED qui sort sur la première LED 
   andi $1, $1, 0xF
   ori  $1, $1, 0x1
   j boucle_infinie
