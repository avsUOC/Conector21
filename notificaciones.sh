#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona las notificaciones y avisos al usuario
###

#Funciona para comprobar los permisos del usuario
noRoot(){
	if [ "$(id -u)" != "0" ]
  	then
	    echo "1"	    
    else
    	echo "0"
	fi
}

#Funcion que comprueba que la tarjeta elegida existe
noCard(){
	cardsIW=$(iw dev|grep Interface| cut -d " " -f2)
    for card in $cardsIW
    do
		if [[ "$card" == "$1" ]]
		then
			echo "0"
			return
		fi
    done
    echo "1"   
}

noMonitor(){
	echo
}

noManaged(){
	echo
}