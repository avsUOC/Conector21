#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona las opciones de detección de ataques
###

fecha=$(date +'%d-%m-%Y')
hora=$(date +'%H:%M')
mkdir ./Capturas 2>/dev/null
mkdir ./Capturas/$fecha 2>/dev/null
directorio="./Capturas/$fecha" 

if [[ "$lenCanales" -le "14" ]]
then
  comandoAir="airodump-ng -i $tarjetaWifi"
else
  comandoAir="airodump-ng -i $tarjetaWifi --band abg"
fi

function menuAttack {
  clear
  estadoT
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e "\e[41m                 MENU - ATAQUES                   \e[0m"
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e ""
  echo -e "\e[39m 1) Detectar ataque tipo Deauth\e[0m"    
  echo -e "\e[39m 2) Realizar ataque tipo Deauth\e[0m" 
  echo -e "\e[39m 3) Detectar clientes de una red\e[0m"
  echo -e ""
  echo -e " v) para Volver al menú anterior"
  echo -e "\n"
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e ""
  echo -ne "$avisoA"; read -r -p "     Introduzca una opción: " opc
  echo -e ""
  case $opc in
    1)
      detectAuth
      menuAttack
    ;;
    2)
      ataqueDeauth
      menuAttack
    ;;
    3)
      verClientes
      menuAttack
    ;;
    v|V)
      menuPrincipal
    ;;
    *)
      menuAttack
    ;;
  esac
}


#***********************************************************Ataques*****************************************************************
#***********************************************************************************************************************************

function ataquearp() {
  clear
  echo "-------------------------------------------------"
  echo "         Ataque ARP"
  echo "-------------------------------------------------"
  sysctl -w net.ipv4.ip_forward=1    
}

function detectAuth() {
  touch $directorio/detectDeauth.pcap 2>/dev/null  
  echo -e ""
  echo -e "$avisoV Si no especifica un canal, mayor dificultad localizar ataques"
  echo -ne "$avisoA Ejecutar en un canal determinado. ¿Si/No?: "; read opc
  if [ "$opc" == "s" ] || [ "$opc" == "S" ]
  then        
    echo -e ""
    echo -ne "$avisoA Indique el canal: "; read canal
    comandoAir="airodump-ng -i $tarjetaWifi -c $canal"
  fi
  monitorIW   
  #Se ejecuta airodump-ng en segundo plano para recorrer todos los canales y analizar el aire
  xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "$comandoAir" &
  pidAirodump=$! #numero de proceso airodump
  
  sleep 2
  #Realizamos la captura del tráfico     
  sudo tcpdump -Z root -i $tarjetaWifi wlan subtype deauth -w $directorio/detectDeauth.pcap &  
  conti="1"
  filedeauth="$directorio/detectDeauth.pcap" 

  clear    
  estadoT 
  echo -e ""
  echo -e ""
  echo -e "\e[41m    BUSCANDO POSIBLES ATAQUES DEAUTH    \e[0m"
  echo -e ""
  echo -e ""
  echo -e "$avisoA Buscando ...\n"
  echo -e "$avisoA Cierre la ventana emergente para continuar \n" 

  #Se sigue buscando hasta que el usuario cierre la ventana
  while [ "$conti" == "1" ]  
  do
    if [ -s "$filedeauth" ]
    then
      clear
      estadoT
      echo -e ""
      echo -e "\e[41m -------------------------------------------------\e[0m"
      echo -e ""
      echo -e "$avisoR $avisoR ¡¡¡Ataque encontrado!!!"
      echo -e ""
      echo -e "\e[41m -------------------------------------------------\e[0m"
      echo -e ""
      echo -e "$avisoV La captura continúa, para finalizar cierre la ventana emergente"
      echo -e ""
      wait $pidAirodump
      killall airodump-ng 2>/dev/null
      killall tcpdump 2>/dev/null
      hora=$(date +'%H:%M')
      mv $directorio/detectDeauth.pcap $directorio/detectDeauth.pcap_$hora
    fi    
    #activeprocess=$pidAirodump         
    sleep 1
    if [ -z "$(pidwait -l airodump-ng)" ]
    then
      echo -e "\n Parando detección ataque..."
      killall tcpdump 2>/dev/null
      killall airodump-ng 2>/dev/null
      conti="0"
      rm $directorio/detectDeauth.pcap 2>/dev/null
      break
    else
      conti="1"
    fi
  done
  echo "Configurando tarjeta..."
  #wait $pidAirodump #esperamos hasta cerrar airodump  
  normalT
}

function verClientes() {
  #Se comprueba que la tarjeta se encuentre en modo managed
  if [ "$monitorEstado" == 1 ]
  then
    normalT
  fi
  echo -e ""
  echo -e "$avisoV Buscando redes inalámbricas ..."
  sudo nmcli dev wifi list ifname $tarjetaWifi
  echo -e ""
  echo -e "$avisoV Configurando la tarjeta...\n"
  ip link set $tarjetaWifi down 2>>./Logs/error_$fecha.txt
  iw $tarjetaWifi set type monitor 2>>./Logs/error_$fecha.txt
  ip link set $tarjetaWifi up 2>>./Logs/error_$fecha.txt
  sleep 1   
  echo -ne "$avisoA ¿Conoce el BSSID?. Si/No: "; read opc
  if [ "$opc" == "s" ] || [ "$opc" == "S" ]
  then
    echo -e ""
    echo -ne "$avisoA Indique el bssid: "; read bssid
    echo -ne "$avisoA Indique el canal: "; read canal
    killall airodump-ng 2>/dev/null
    xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "$comandoAir -c $canal --bssid $bssid" &
    pidClientes=$!
    touch $directorio/detectClientes_$hora.pcap
    sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/detectClientes_$hora.pcap & 
    echo -e ""
    echo -e "$avisoV Para finalizar cierre la ventana emergente"
    echo -e ""
    wait $pidClientes
    killall airodump-ng 2>/dev/null
    killall tcpdump 2>/dev/null
  else
    echo -e ""
    echo -e "$avisoV Para finalizar el proceso en cualquier instante, pulse Ctrl+C"
    xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "$comandoAir" &
    echo -e ""
    echo -e "$avisoV Pulse la barra espaciadora para detener la vista"
    echo -e ""
    echo -ne "$avisoA Indique el canal: "; read canal
    killall airodump-ng 2>/dev/null
    xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "$comandoAir -c $canal" &
    echo -e ""
    echo -ne "$avisoA Indique el bssid: "; read bssid
    killall airodump-ng 2>/dev/null
    xterm -fg white -bg black -fa 'Monospace' -fs 10 -e "$comandoAir -c $canal --bssid $bssid" &
    pidClientes=$!
    sudo tcpdump -Z root -v -i $tarjetaWifi -C 20 -w $directorio/detectClientes_$hora.pcap & 
    echo -e ""
    echo -e "$avisoV Para finalizar cierre la ventana emergente"
    echo -e ""
    wait $pidClientes
    killall airodump-ng 2>/dev/null
    killall tcpdump 2>/dev/null
    echo -e ""
  fi
  echo -e ""
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e ""
  echo -e "              Posibles clientes detectados"
  echo -e ""
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e ""
  sudo tshark -nr $directorio/detectClientes_$hora.pcap -Y '(wlan.ta == '$bssid') || (wlan.da == '$bssid') && (wlan.fc.type == 2) && !(wlan.fc.subtype == 8) && !(wlan.fc.subtype == 0)' -Tfields -e wlan.ta -e wlan.da |sort|uniq|grep -v ff
  echo -e ""
  echo -e "\e[41m -------------------------------------------------\e[0m"
  echo -e ""
  echo -ne "$avisoA Pulse ENTER para continuar "; read
}

