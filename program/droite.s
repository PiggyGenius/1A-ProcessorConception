.text
	ori $a0,$zero,40
	ori $a1,$zero,0
	ori $a2,$zero,0x07E0
	ori $a3,$zero,280
	jal trace_simple 
boucle: 
	j boucle

trace_simple: 
# fonction tracant un segment du point [x=$a0,y=$a1] au point [x=$a3-1, y=$a1+($a3-$a0)-1] avec la couleur $a2
# contexte :
# $a0 =x
# $a1=y
# $a2=couleur
# $t9 = sauvegarde de $ra 

	ori $t9,$ra,0	# Sauvegarde l'adresse de retour ($ra) dans un registre qui ne sera pas utilise par la suite ($t9)
for: 			# for(;$a0!=$a3;$a0++){ affiche_pixel($a0,$a1,$a2); $a1++;}
	beq $a3,$a0,fin_for
	jal affiche_pixel
	addi $a0,$a0,1
	addi $a1,$a1,1
	j for
fin_for:
	ori $ra,$t9,0	# Restaure $ra
	jr $ra 

affiche_pixel: 
# contexte : 
# $a0 =x 
# $a1=y 
# $a2=couleur

# On calcule l'adresse du pixel à la coordonnée(x,y) : 0x80000 + (320*y +x)*4 = 0x80000 + (y<<8)+(y<<10)+(x<<2)
    lui $t0, 8
    sll $t1, $a0, 2
    addu $t0, $t0, $t1
    sll $t1, $a1, 8
    addu $t0, $t0, $t1
    sll $t1, $a1, 10
    add $t0, $t0, $t1
	sw $a2,0($t0)	
	jr $ra
