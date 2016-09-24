BEGIN {eo=0; ad_prev=-1;}

/^[0-9a-f]+ /{
ad=strtonum("0x" $1);
adc=sprintf("%08x",ad);
if (ad!=ad_prev) 
{
if (eo) print "FFFFFFFF";
print "@" adc; 
}
eo=1;
ad_prev=ad;
}

/^[ \t]+[0-9a-f]+:\t/{
adc=$1
gsub(":","",adc);
ad=strtonum("0x" adc);
adc=sprintf("%08x",ad);

if (NF>=6 && length($5)==8)
{
if (ad!=ad_prev)
{
if (eo) print "FFFFFFFF";
print "@" adc;
}
for(jj=2;jj<6;jj++)
print $jj;
ad_prev=ad+4*3;
}
else
{
if (ad==ad_prev)
print $2;
else
{
if (eo) print "FFFFFFFF";
print "@" adc;
print $2
ad_prev=ad;
}
}
ad_prev+=4;
eo=1;
}
END { 
if (ad_prev < 0x2000)
print "FFFFFFFF";
}

