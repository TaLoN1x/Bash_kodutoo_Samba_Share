#!/bin/bash
#Autor Juri Kononov, rühm A21
#Bashi kodutöö, teeb võrgusheeri Samba abil.
export LC_ALL=C
#loon konstanti konfi faili backupimiseks.
NOW=$(date +"%Y-%m-%d-%H-%M")-$(shuf -i 1-99 -n 1)

#kontrollin, kas samba on paigaldatud süsteemis või mitt
dpkg -s samba | grep "Status: install ok installed" 
if [ $? -eq 0 ]
then 
    echo "Samba on instaleeritud"
else
    echo "Samba ei ole instaleeritud"
    apt-get update && apt-get install samba smbclient
fi

#kas kasutaja on root õigustes?
if [ $UID -ne 0 ]
then
    echo "Kasutajal pole õigusi skripti käivitamiseks, logi juurkasutajaga"
    exit 1
fi

#parameetrite kontroll
KAUST=$1
GRUPP=$2
if [ $# -eq 3 ]
then
    SHARE=$3
elif [ $# -eq 2 ]
then
    SHARE=$(basename $KAUST)
else 
    echo "Parameetrid on valesti sisestatud, käivita programm järgnevalt:"
    echo "$0 KAUST GRUPP [SHARE]"
    exit 1
fi
    echo "Jagan kausta $KAUST gruppile $GRUPP nimega $SHARE !"

#gruppi olemasolu kontroll

if [ $(getent group $GRUPP ) ] 
then
    echo "Grupp eksisteerib"
else 
    echo "Gruppi ei eksisteeri, loon gruppi"
    groupadd $GRUPP
fi
#kausta olemasolu kontroll
if [ -d "$KAUST" ] 
then
    echo "Kaust on juba olemas" #ajutine veateade
    echo "Loon SHARI"
    chgrp $GRUPP $KAUST
    chmod g+w $KAUST
    chmod g+s $KAUST
else 
    echo "Loon kausta $KAUST"
    mkdir $KAUST -p
    chgrp $GRUPP $KAUST
    chmod g+w $KAUST
    chmod g+s $KAUST
fi
#teeme konfidest bacup
cp /etc/samba/smb.conf /etc/samba/smb.conf.old.$NOW

#Kannan andmeid konfifaili

cat >> /etc/samba/smb.conf << end
[$SHARE]
path = $KAUSK
read only = no
valid users = @$GRUPP
force group = $GRUPP
create mask = 770
directory mask = 770
end

#taaskäivitame SMB teenust
service smbd reload
echo "Sheerimiskript on oma tööd edukalt lõpenud."
exit 0
