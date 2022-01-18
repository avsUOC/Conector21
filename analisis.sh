#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona la obtencion de informacion de los dispositivos
#conectados a nuestra misma red
###

#***************************************************Info, NMAP, Tracert************************************************************
#**********************************************************************************************************************************

function menuAnalisis() {
  echo -e ""
  #Se comprueba que existe conexión con una red  
  connected=$(nmcli con show -a| grep -o $tarjetaWifi)
  if [ "$tarjetaWifi" == "$connected" ]
  then
    menuNMAP
    echo -e "$avisoV Direcciones IP actuales: "
    hostname -I | tr -s '[:blank:]' '\n'
    echo -e ""
    echo -ne "$avisoA Indique NOMBRE del análisis: "; read nombre
    echo -e ""
    echo -e "$avisoA Introduzca la IP para analizar"
    echo -e "$avisoV Rango propuesto: $(ip addr show $tarjetaWifi| grep -w inet | awk '{print $2}')"
    echo -ne "$avisoA IP: ";read direccion
    menuAcciones
   else
    echo -e ""
    echo -e "$avisoR No está conectado a ninguna red"
    echo -e "$avisoR Utilize la opción 2 para conectarse"
    sleep 2    
    menuPrincipal
  fi
}

function menuNMAP(){
    clear
    estadoT
    echo -e "\e[43m ------------------------------------------------- \e[0m"
    echo -e "\e[43m                NMAP - MENU                        \e[0m"
    echo -e "\e[43m ------------------------------------------------- \e[0m"
    echo -e ""
    echo -e " 1) NMAP -O / agresividad alta / limitación puertos comunes / obtiene sistema operativo / múltiples IP"
    echo -e " 2) NMAP -T2 / agresividad media / limitación puertos comunes (más lento) / múltiples IP"
    echo -e " 3) NMAP -T1 / agresividad baja (invisible) / limitación puertos comunes / muy lento, reducir a 1 única IP"
    echo -e " 4) NMAP 65535 / agresividada alta / sin limitación de puertos / muy lento, reducir a 1 única IP"
    echo -e " 5) NAMP -A / agresividad alta / 1000 puertos más comunes / obtiene la máxima información posible / muy lento, reducir a 1 única IP"
    echo -e " 6) ARP Scan / análisis de protocolo ARP / múltiples IP"
    echo -e " 7) NetDiscover / análisis de protocolo ARP / múltiples IP"
    echo -e " 8) Tablas de direccionamiento y saltos de conexión"
    echo -e ""
    echo -e " c) para Cambiar las direcciones de red"
    echo -e " v) para Volver al menú anterior"
    echo -e ""
    echo -e "\e[43m ------------------------------------------------- \e[0m"
    echo -e ""
}

function menuAcciones() { 
    menuNMAP
    fecha=$(date +'%d-%m-%Y')
    hora=$(date +'%H:%M')
    mkdir ./Info/$nombre 2>/dev/null
    mkdir ./Info/$nombre/$fecha 2>/dev/null
    directorio="./Info/$nombre/$fecha"
    echo -e "$avisoV Nombre del análisis: $nombre"
    echo -e "$avisoV IP(s) para analizar: $direccion"
    echo -e ""
    echo -e "\e[43m ------------------------------------------------- \e[0m"
    echo -e ""
    read -r -p "Introduzca una opción: " opc
    case $opc in
      1)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/NMAP-$hora.txt
        nmap -v -p22,25,53,80,137-139,143,336,443,445,554,1900,5000,5431,7000,7100,8009,8080,9000,30000,49152,62078 $direccion >> $directorio/NMAP-$hora.txt
        touch $directorio/NMAP-T3-O-$hora.txt
        nmap -T3 -O -v -p22,25,53,80,137-139,143,336,443,445,554,1900,5000,5431,7000,7100,8009,8080,9000,30000,49152,62078 $direccion >> $directorio/NMAP-T3-O-$hora.txt #Poniendo -O da más info pero muuuyy lento
        echo -e "$avisoV Análisis finalizado. Fichero creado en: $directorio/NMAP-T3-O-$hora.txt"        
      ;;

      2)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/NMAP-T2-$hora.txt
        nmap -T2 -Pn -v -p22,25,53,80,137-139,143,336,443,445,554,1900,5000,5431,7000,7100,8009,8080,9000,30000,49152,62078 $direccion >> $directorio/NMAP-T2-$hora.txt #No utiliza el ping, con T2 menos agresivo
        echo -e "$avisoV Análisis finalizado. Fichero creado en: $directorio/NMAP-T2-$hora.txt"
      ;;

      3)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/NMAP-T1-$hora.txt
        nmap -T1 -sn -vvv  $direccion >> $directorio/NMAP-T1-$hora.txt #No utiliza el ping, con T1 poco agresivo
        echo -e "$avisoV Análisis finalizado. Fichero creado en: $directorio/NMAP-T1-$hora.txt"
      ;;

      4)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/NMAP-Services-$hora.txt
        nmap -p1-65535 -v $direccion >> $directorio/NMAP-Services-$hora.txt #T3 normal, puede tardar bastante según la red
        echo -e "$avisoV Análisis finalizado. Fichero creado en: $directorio/NMAP-Services-$hora.txt"
      ;;

      5)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/NMAP-A-$hora.txt
        nmap -A -T4 $direccion >> $directorio/NMAP-A-$hora.txt
        echo -e "$avisoV Análisis finalizado. Fichero creado en: $directorio/NMAP-A-$hora.txt"
      ;;

      6)
        echo -e ""
        echo -e "$avisoV Analizando direccion(es): $direccion ..."
        echo -e ""
        touch $directorio/arpScan-$hora.pcap
        arp-scan $direccion -W $directorio/arpScan-$hora.pcap 2>/dev/null
        echo -e ""
        sleep 1
      ;;

      7)
        #touch $directorio/netDiscover-$hora.txt
        echo -ne "¿Utilizar modo "invisible". Si/No? "; read opc;
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
          echo -e "$avisoA Analizando red..."
          xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo netdiscover -p -i $tarjetaWifi -r $direccion" & 
          pidNet=$!
          echo -e "$avisoA Cierre la ventana emergente para continuar..."
          wait $pidNet
        else
          echo -e "$avisoA Analizando red..."
          xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo netdiscover -i $tarjetaWifi -r $direccion" &
          pidNet=$!
          echo -e "$avisoA Cierre la ventana emergente para continuar..."
          wait $pidNet 
        fi    
        menuAcciones   
      ;;

      8)
        touch $directorio/enrutado-$hora.txt
        touch $directorio/tracert-$hora.txt
        echo -e "*****************ROUTE********************" >> $directorio/enrutado-$hora.txt
        ip route list >> $directorio/enrutado-$hora.txt
        echo "Introduce IP pública para comprobar enrutado y tracert. Ej: 8.8.8.8 (google)"
        read ipdir
        ip route get $ipdir >> $directorio/enrutado-$hora.txt
        echo -e "\n"
        #echo -e "*****************ROUTE********************"
        cat $directorio/enrutado-$hora.txt
        #cat $directorio/enrutadoTracert-$hora.txt
        echo -e ""
        echo "*****************TRACERT******************" >> $directorio/tracert-$hora.txt
        #echo "*****************TRACERT******************"
        tracepath -n -m 6 $ipdir >> $directorio/tracert-$hora.txt
        cat $directorio/tracert-$hora.txt
        echo -e ""        
      ;;

      c|C)
        echo -e ""
        echo -ne "$avisoA Indique NOMBRE del análisis: "; read nombre
        echo -e ""
        echo -e "$avisoA Introduzca la IP para analizar"
        echo -e "$avisoV Rango propuesto: $(ip addr show $tarjetaWifi| grep -w inet | awk '{print $2}')"
        echo -ne "$avisoA IP: ";read direccion
        menuAcciones
      ;;

      v|V)
        menuPrincipal
      ;;

      *)        
        menuAcciones
      ;;
    esac  
    echo -e ""
    echo -e "$avisoV Ficheros del análisis $nombre"
    ls -la $directorio | grep -e txt -e pcap | awk '{print $9}' | nl
    echo -e ""
    echo -ne "$avisoA Pulse ENTER para continuar"; read
    menuAcciones
 
}