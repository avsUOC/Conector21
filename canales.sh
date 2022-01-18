#!/bin/bash


###############Canales 24
function canales24Detect() {
	echo -e "\n"
	i=0
	declare -a canales24
	while [[ "$i" -le "$lenCanales" ]]
	do
		canales24+=("${canalesIW[$i]#0} ")
		i=$((i+1))		
	done  
	#Imprimimos los canales 24
	len24=${#canales24[@]} 
}

function canal24Print() {
	echo -e "Canales 2.4GHz"
	for (( i=0; i<$len24; i++ )); do 
		echo -en " ${canales24[$i]#0}"
	done
	echo -e "\n"
}

function canal24Recorre() {
	for (( i=0; i<$len24; i++ )); do 
		iw $tarjetaWifi set channel ${canales24[$i]#0}
		iw dev $tarjeta info | grep -i channel
		sleep 1
	done
}

###############Canales 5
function canales5Detect(){
	echo -e "\n"
	declare -a canales5
	for (( i=$len24; i<$lenCanales; i++ ))
	do
		canales5+=("${canalesIW[$i]#0} ")
	done	
}

function canal5Print(){
	len5=${#canales5[@]}   
	#Imprimimos los canales 
	echo -e "Canales 5GHz"
	for (( i=0; i<$len5; i++ )); do 
		echo -en " ${canales5[$i]#0}"
	done
	echo -e "\n"	
}

###############Todos los canales
function canalesPrint(){
	echo -e "$avisoV Todos los Canales soportados"
	for (( i=0; i<$lenCanales; i++ )); do 
		echo -en " ${canalesIW[$i]#0}"
	done
	echo -e ""
}

#Inicio del script
#Creamos un array con los canales aceptados por la tarjeta
phyWifi=$(iw dev | grep -i $tarjetaWifi -B 10 | grep phy)
canales=$(iw $phyWifi info | grep dBm | awk '{print $4}'| tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]' | xargs)

IFS=' ' read -r -a canalesIW <<< "$canales"

#IFS=' ' read -r -a canalesIW <<< "$(iwlist $tarjetaWifi freq|grep Cha| grep -v Freq|awk '{print $2}' | xargs)"
lenCanales=${#canalesIW[@]}

export lenCanales

if [ "$lenCanales" -le "14" ]
then
	canales24Detect
else
	canales24Detect
	canales5Detect
fi
