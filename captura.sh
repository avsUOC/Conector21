#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona las capturas de trafico
###

#Avisos por colores
avisoV="\e[32m[*]\e[0m"
avisoA="\e[33m[->]\e[0m"
avisoR="\e[31m[!]\e[0m"
finCol="\e[0m"

#***************************************************SubMENU Tráfico*****************************************************************
#***********************************************************************************************************************************

function menuTrafico(){
    clear
    estadoT
    echo -e "\e[42m ------------------------------------------------- \e[0m"
    echo -e "\e[42m                CAPTURA - MENU                     \e[0m"
    echo -e "\e[42m ------------------------------------------------- \e[0m"
    echo -e ""
    echo -e " 1) Captura indicando un canal"
    echo -e " 2) Captura en canales 2.4GHz"
    echo -e " 3) Captura en canales 5GHz"
    echo -e " 4) Todo el espectro"
    echo -e ""
    echo -e " v) para Volver al menú anterior"
    echo -e ""
    echo -e "\e[42m ------------------------------------------------- \e[0m"
    echo -e ""
}

function menuCaptura() {
  clear
  menuTrafico
  fecha=$(date +'%d-%m-%Y')
  hora=$(date +'%H:%M')
  mkdir ./Capturas 2>/dev/null
  mkdir ./Capturas/$fecha 2>/dev/null
  directorio="./Capturas/$fecha"   
  connected=$(iw dev $tarjetaWifi info | grep ssid)
  if [[ -z $connected ]]
  then
    #Si no está conectado a ninguna red
    echo -e ""
    echo -ne "$avisoA";read -r -p "  Introduzca una opción: " opc
    case $opc in
      1)
        if [ "$monitorEstado" == 0 ]
        then
          monitorIW 
        fi
        canalesPrint
        canalIW   
        clear
        estadoT
        echo -e "\e[42m ------------------------------------------------- \e[0m"
        echo -e ""
        echo -e "$avisoV \e[42m Capturando tráfico en canal $canal...\e[0m" 
        echo -e ""
        xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo airodump-ng -i $tarjetaWifi -c $canal" & 
        echo -e "$avisoV Pulse [Ctrl+C] para finalizar la captura  \n"
        sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/AireCanal_$hora.pcap
        pidDump=$!
        wait $pidDump
        sudo killall airodump-ng 2>/dev/null
        sleep 1
        echo -e ""
        echo -e "$avisoV Fichero creado: $directorio/AireCanal_$hora.pcap"
        echo -e ""
        echo -ne "$avisoA"; echo -ne " ¿Buscar posibles paquetes EAPOL?. Si/No "; read opc
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
            echo -e ""
            tshark -nr $directorio/AireCanal_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e "\e[42m ------------------------------------------------- \e[0m"
            echo -e ""
            echo -e "Pulse ENTER para continuar"
            read
        fi
        menuCaptura
      ;;
      2)
        if [ "$monitorEstado" == 0 ]
        then
          monitorIW 
        fi
        #len24=${#canales24[@]}
        #for (( i=0; i<$len24; i++ )); do 
        #  echo -en " ${canales24[$i]#0}"
        #done 
        clear
        estadoT
        echo -e "\e[42m ------------------------------------------------- \e[0m"
        echo -e ""
        echo -e "$avisoV \e[42m Capturando tráfico en la banda 2.4GHz \e[0m" 
        xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo airodump-ng -i $tarjetaWifi --band bg" & 
        echo -e ""
        echo -e "$avisoV Pulse [Ctrl+C] para finalizar la captura  \n"
        sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/Aire2_$hora.pcap
        pidDump=$!
        wait $pidDump
        sudo killall airodump-ng 2>/dev/null
        sleep 1
        echo -e ""
        echo -e "$avisoV Fichero creado: $directorio/Aire2_$hora.pcap"
        echo -e ""
        echo -ne "$avisoA"; echo -ne " ¿Buscar posibles paquetes EAPOL?. Si/No "; read opc
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
            echo -e ""
            tshark -nr $directorio/Aire2_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e "\e[42m ------------------------------------------------- \e[0m"
            echo -e ""
            echo -e "Pulse ENTER para continuar"
            read
        fi
        menuCaptura
      ;;
      3)
        #Se comprueba que la tarjeta soporta canales de 5GHz
        if [ "$lenCanales" -le "14" ]
        then
          echo -e ""
          echo -e "$avisoR La tarjeta $tarjetaWifi no soporta frecuencias 5GHz"
          menuTrafico        
        fi
        if [ "$monitorEstado" == 0 ]
        then
          monitorIW 
        fi        
        clear
        estadoT
        echo -e "\e[42m ------------------------------------------------- \e[0m"
        echo -e ""
        echo -e "$avisoV \e[42m Capturando tráfico en la banda 5GHz \e[0m" 
        xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo airodump-ng -i $tarjetaWifi --band a" & 
        echo -e ""
        echo -e "$avisoV Pulse [Ctrl+C] para finalizar la captura  \n"
        sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/Aire5_$hora.pcap
        pidDump=$!
        wait $pidDump
        sudo killall airodump-ng 2>/dev/null
        sleep 1
        echo -e ""
        echo -e "$avisoV Fichero creado: $directorio/Aire5_$hora.pcap"
        echo -e ""
        echo -ne "$avisoA"; echo -ne " ¿Buscar posibles paquetes EAPOL?. Si/No "; read opc
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
            echo -e ""
            tshark -nr $directorio/Aire5_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e "\e[42m ------------------------------------------------- \e[0m"
            echo -e ""
            echo -e "Pulse ENTER para continuar"
            read
        fi
        menuCaptura
      ;;  
      4)
        if [ "$monitorEstado" == 0 ]
        then
          monitorIW 
        fi
        clear
        estadoT
        echo -e "\e[42m ------------------------------------------------- \e[0m"
        echo -e ""
        echo -e "$avisoV \e[42m Capturando tráfico en la banda 2.4GHz \e[0m" 
        xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "sudo airodump-ng -i $tarjetaWifi --band abg" & 
        echo -e ""
        echo -e "$avisoV Pulse [Ctrl+C] para finalizar la captura  \n"
        sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/AireTodo_$hora.pcap
        pidDump=$!
        wait $pidDump
        sudo killall airodump-ng 2>/dev/null
        sleep 1
        echo -e ""
        echo -ne "$avisoA"; echo -ne " ¿Buscar posibles paquetes EAPOL?. Si/No "; read opc
        if [ "$opc" == "s" ] || [ "$opc" == "S" ]
        then
            echo -e ""
            tshark -nr $directorio/AireTodo_$hora.pcap |grep -i eapol|awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
            echo -e ""
            echo -e "\e[42m ------------------------------------------------- \e[0m"
            echo -e ""
            echo -e "Pulse ENTER para continuar"
            read
        fi
        menuCaptura
      ;;   
      v|V)
        if [ "$monitorEstado" == 1 ]
        then
          normalT
        fi         
        menuPrincipal
      ;;
       *)
        menuTrafico
      ;;

    esac

    #tshark -r Capturas/08-12-2021/AireCanal_20\:39.pcap |grep -i eapol

    monitorIW 
    canalIW   
    clear
    estadoT   
    echo "$canalSet"
    if [ "$canalSet" != 0 ]
    then
      #sudo gnome-terminal -- airodump-ng -c $canal $tarjeta & 
      #sudo gnome-terminal -x bash -c "./tcpdumpNoCanal.sh; exec bash" &

      #xterm -hold -e "airodump-ng -c $canal wlo1" &
      #pidAirodump=$!
      #kill -9 $pidAirodump
      #wait $pidAirodump 2>/dev/null

      #airodump-ng -c $canal $tarjeta 1>/dev/null 2>>./Logs/airodump_$fecha.txt &  #1>/dev/null 
      echo -e "\e[33m[*]\e[0m Capturando tráfico en canal $canal...             "    
    else
      #sudo gnome-terminal -- airodump-ng $tarjeta &
      airodump-ng $tarjetaWifi 1>/dev/null & 2>>./Logs/airodump_$fecha.txt
      echo -e "\e[33m[*]\e[0m Capturando tráfico en todos los canales...             "    
      #sudo gnome-terminal -x bash -c "./tcpdumpNoCanal.sh $tarjeta; exec bash" &
    fi
    
    echo -e ""
    echo -e "\e[33m[*]\e[0m Pulse [Ctrl+C] para finalizar la captura  \n"
    fecha=$(date +'%Y-%m-%d_%H::%M:%S')
    sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/Aire_$hora.pcap
    pidDump=$!
    wait $pidDump
    #sh ./tcpdumpNoCanal.sh $tarjeta $fecha $! & PIDIOS=$! #2>>./Logs/tcpdump_$fecha.txt    
    #sh ./tamano.sh $fecha & PIDMIX=$!
    #wait $PIDIOS
    #wait $PIDMIX
    #read
    sleep 1
    normalT
  else   
    #Si está conectado a una red 
    echo -e "\e[33m[*]\e[0m Capturando tráfico de la red interna..."
    echo -e "\e[33m[*]\e[0m Pulse Ctrl+C para finalizar la captura\n"    
    fecha=$(date +'%Y-%m-%d_%H::%M:%S')    
    tcpdump -Z root -v -i $tarjetaWifi -C 20 -w ./Capturas/RedInterna_$fecha.pcap #2>>./Logs/tcpdump_$fecha.txt
    pidDump=$!
    wait $pidDump
  fi    
  echo -e "\n"
  killall airodump-ng 2>>./Logs/airodump_$fecha.txt
  sleep 1   
}