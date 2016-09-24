.text
# On place dans $1 un index
ori $1,$0,21 
# On place un masque dans $2 correspondant à la valeur 2^index
ori $2,$0,1
sllv $2,$2,$1
# On place un compteur dans $3 qu'on incrémente (on se fiche de la valeur initiale)
addiu $3,$3,1
# On regarde si le compteur active le masque. 
# Le résultat est placé dans $4 : 0 ou 1
and $4,$3,$2
srlv $4,$4,$1
# Si la valeur ($4) change par rapport à celle de l'itération précédente ($6), on détecte un évènement de période 2^index*durée_itérations
# Le changement est mis dans $5
xor $5,$4,$6
# On conserve la valeur courante dans $6
or $6,$0,$4
# Le motif à afficher est dans $7. 
# On le décale de $5 (0 ou 1) position vers la gauche 
sllv $7,$7,$5
# On allume le bit de poids faible
ori $7,$7,1
# On envoie sur les LED pour MMIPS simple
or $28,$0,$7
# Via l'instruction de garde que rajoute l'assembleur, on réinitialise PC.
# Donc on reboucle sur la première instruction.
