#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona las opciones sobre la tarjeta de red
###

#***************************************************Monitor*************************************************************************
#***********************************************************************************************************************************
function menuTarjeta() {
	opc="s"
  connected=$(nmcli con show -a|grep -o $tarjetaWifi)
  clear
	estadoT
	echo -e "\e[44m ------------------------------------------------- \e[0m"
	echo -e "\e[44m                 Menu - TARJETA                    \e[0m"
	echo -e "\e[44m ------------------------------------------------- \e[0m"
	echo -e ""
	echo -e " 1) Modo - Managed"
	echo -e " 2) Modo - Monitor"
	echo -e " 3) Reiniciar Tarjeta"
  echo -e " 4) Cambio de MAC"
  echo -e " 5) Cambio Hostname"
  echo -e ""
	echo -e " v) para Volver al menú anterior"
  echo -e ""
	echo -e "\e[44m ------------------------------------------------- \e[0m"
  if [[ -n "$connected" ]]
  then
    echo -e "$avisoV            Está conectado a una red"
    echo -e "$avisoV Cualquier opción elegida, finalizará dicha conexión"
  fi
  echo -e ""
	echo -ne "$avisoA"; read -r -p "     Introduzca una opción: " opc
  echo -e ""

	case $opc in
  1)
    normalT
    menuTarjeta
  ;;

  2)			
    monitorIW
    #canalIW
    menuTarjeta
  ;;
  
  3)
    echo -e "\e[33m[*]\e[0m Modificando el estado de la tarjeta..."
    sudo nmcli radio wifi off
    sleep 2
    sudo nmcli radio wifi on
    menuTarjeta
  ;;

  4)
    menuMAC
    menuTarjeta
  ;;

  5)
    menuHostname
    menuTarjeta
  ;;

  v|V)
    menuPrincipal			
  ;;

  *)
    menuTarjeta
  ;;
	esac

}

function monitorIW(){
  #clear
  echo -e "\n $avisoV Configurando la tarjeta...\n"
  ip link set $tarjetaWifi down 2>/dev/null
  iw $tarjetaWifi set type monitor 2>/dev/null
  ip link set $tarjetaWifi up 2>/dev/null
  sleep 1  
  monitorEstado=1 
}

function canalIW(){
  echo -e "\n"
  echo -e "$avisoV Indique un canal de la lista. Ej: 6 o 40"
  echo ""
  read canal
  len=${#canalesIW[@]}
  encontrado=0
  for (( i=0; i<$len; i++ ))
  do   
    #Comprobamos que el canal está soportado por la tarjeta
    if [[ "${canalesIW[$i]#0}" == "$canal" ]]
    then 
      iw $tarjetaWifi set channel $canal
      encontrado=1
      break
    fi      
  done
  if [ "$encontrado" -eq 1 ]
  then
    break
  else
    echo -e "$avisoR El canal indicado no está soportado por la tarjeta"  
    echo -e "$avisoV Indique un canal válido"
    sleep 2
    clear
    menuCaptura
    #canalIW
  fi
}

function normalT() {
  #clear	
  echo -e "\n $avisoV Configurando la tarjeta ...\n"
  ip link set $tarjetaWifi down 2>/dev/null
  iw $tarjetaWifi set type managed 2>/dev/null
  ip link set $tarjetaWifi up 2>/dev/null
  monitorEstado=0
  sleep 1     
}

#***************************************************SubMENU MAC*********************************************************************
#***********************************************************************************************************************************
function menuMAC() {
  #opcion2="s"
  clear
  estadoT
	echo -e "\e[44m ------------------------------------------------- \e[0m"
	echo -e "\e[44m                  Cambio de MAC                    \e[0m"
	echo -e "\e[44m ------------------------------------------------- \e[0m"
  echo -e ""
	echo -e " 1) MAC de XIAOMI"
	echo -e " 2) MAC de SAMSUNG"
	echo -e " 3) MAC de APPLE"
	echo -e " 4) MAC Aleatoria"
	echo -e " 5) MANUAL"
  echo -e " 6) Restaurar MAC original"
	echo -e " v) Volver al menú anterior \n"
	echo -e "\e[44m ------------------------------------------------- \e[0m"
  echo -e ""
  echo -ne "$avisoA"; read -r -p "     Introduzca una opción: " opc
  echo -e ""
	case $opc in
    1)
    tipomac="XIAOMI"
    dirMac="A8:9C:ED:"
    cambio_mac
    ;;

    2)
    tipomac="SAMSUNG"
    dirMac="BC:7A:BF:" 
    cambio_mac
    ;;

    3)
    tipomac="APPLE"
    dirMac="10:40:F3:"
    cambio_mac
    ;;

    4)
    echo -e "\e[44m           Generación aleatoria de MAC            \e[0m"
    echo -e ""
    #ip link show $tarjetaWifi | grep ether |xargs | cut -d' ' -f2
    ip link set dev $tarjetaWifi down		    
    macchanger -r $tarjetaWifi
    sleep 1
    ip link set dev $tarjetaWifi up
    echo -e ""
    #echo -e "\e[44m                  MAC aleatoria                    \e[0m"
    #macchanger -s $tarjetaWifi |grep -i current |xargs|cut -d' ' -f3-100
    #echo -e ""
    echo -e "$avisoV Cambio realizado"    
    echo -e "$avisoA Pulse ENTER para continuar"    
    read
    ;;

    5)
    echo -e ""
    echo -e "\e[44m                    MAC Manual                    \e[0m"    
    echo -e ""
    echo -e "$avisoV Formato: 11:22:33:44:55:66"
    echo -ne "$avisoA Introduzca la nueva dirección MAC: "; read MacFinal
    echo -e ""
    oldMAC=$(ip link show $tarjetaWifi | grep ether | awk '{print $2}')
    ip link show $tarjetaWifi | grep ether
    ip link set dev $tarjetaWifi down 2>/dev/null
    ip link set dev $tarjetaWifi address $MacFinal 2>/dev/null
    ip link set dev $tarjetaWifi up 2>/dev/null
    sleep 0.5
    newMAC=$(ip link show $tarjetaWifi | grep ether | awk '{print $2}')
    if [[ "$new" -eq "$old" ]]
    then
      echo -e ""
      echo -e "$avisoR No se ha podido realizar el cambio de MAC"
      sleep 2
      menuMAC
    else
      echo -e ""
      echo -ne "$avisoV Cambio realizado: "; ip link show $tarjetaWifi | grep ether     
      echo -e "$avisoA Pulse ENTER para continuar"    
      read
    fi      
    ;;

    6)
    MacFinal=$(ethtool -P $tarjetaWifi|cut -d' ' -f3)
    ip link set dev $tarjetaWifi down 2>/dev/null
    ip link set dev $tarjetaWifi address $MacFinal 2>/dev/null
    ip link set dev $tarjetaWifi up 2>/dev/null
    echo -e "\e[44m   Restaurando MAC original...  \e[0m"
    sleep 2
    ;;

    v|V)
    menu
    ;;

    *)
    menuMAC
    ;;

	esac
}

function cambio_mac() {
    echo -e "\e[44m                  MAC original                    \e[0m"
    LETRA=$(cat /dev/urandom| tr -dc 'A-F0-9' | fold -w 32 | head -n1 | cut -c1-6)
    LETRA=${LETRA:0:2}:${LETRA:2:2}:${LETRA:4:2}
    MacFinal="${dirMac}${LETRA}"
    ip link show $tarjetaWifi | grep ether
    ip link set dev $tarjetaWifi down 2>/dev/null
    sleep 1
    ip link set dev $tarjetaWifi address $MacFinal 2>/dev/null
    sleep 1
    ip link set dev $tarjetaWifi up 2>/dev/null
    sleep 1
    echo -e ""
    echo -e "\e[44m                  MAC tipo $tipomac         \e[0m"
    ip link show $tarjetaWifi | grep ether
    echo -e ""
    echo -e "$avisoV Cambio realizado"    
    echo -e "$avisoA Pulse ENTER para continuar"    
    read
}

#***************************************************SubMENU HOSTNAME*******************************************************************
#***********************************************************************************************************************************

function menuHostname() {
    #opcion2="s"
    clear
    estadoT
    echo -e "\e[44m ------------------------------------------------- \e[0m"
    echo -e "\e[44m                 Cambio de Hostname                \e[0m"
    echo -e "\e[44m ------------------------------------------------- \e[0m"
    echo -e ""
    echo -e " 1) Hostname XIAOMI"
    echo -e " 2) Hostname SAMSUNG"
    echo -e " 3) Hostname APPLE"
    echo -e " 4) MANUAL"
    echo -e " 5) Restaurar Hostname original"
    echo -e " "
    echo -e " v) para Volver al menú anterior"
    echo -e ""
    echo -e "\e[44m ------------------------------------------------- \e[0m"
    echo -e ""
    echo -ne "$avisoA"; read -r -p "     Introduzca una opción: " opc
    echo -e ""
    case $opc in
        1)
        echo -e "\e[44m                    HOSTNAME Xiaomi                    \e[0m"    
        hostname >> ./Info/Hostname.txt
        nmcli general hostname Xiaomi		
        ;;

        2)
        echo -e "\e[44m                    HOSTNAME Samsung                    \e[0m"    
        hostname >> ./Info/Hostname.txt
        nmcli general hostname Samsung
        ;;

        3)
        echo -e "\e[44m                    HOSTNAME Apple                    \e[0m"    
        hostname >> ./Info/Hostname.txt
        nmcli general hostname Apple
        ;;
        
        4)
        echo -e "\e[44m                    HOSTNAME Manual                    \e[0m" 
        hostname >> ./Info/Hostname.txt
        echo -e ""
        echo -ne "$avisoA Introduzca el nuevo Hostname: "; read namehost
        echo -e ""
        nmcli general hostname $namehost
        echo -e ""
        echo -e "$avisoV Restauración completada"    
        echo -e "$avisoA Pulse ENTER para continuar"
        menuTarjeta		
        ;;
        
        5)        
        if [ -f ./Info/Hostname.txt ]
        then
          hostnameOld=$(cat Info/Hostname.txt |head -n1)
          nmcli general hostname $hostnameOld 2>/dev/null
          rm ./Info/Hostname.txt           	
        else
          echo -e ""
          echo -e "$avisoR No se puede realizar la restauración, no existe el fichero: $hostnameOld"
          echo -e ""
          sleep 2
          menuHostname		  
        fi        
        ;;
        
        v|V)
          menuTarjeta
        ;;

        *)
          menuHostname
        ;;

    esac  
    echo -e ""     
    echo -e "$avisoV El nuevo hostname es: \e[44m $(hostname) \e[0m"     
    echo -e ""
    echo -e "$avisoV Cambio realizado"    
    echo -e "$avisoA Pulse ENTER para continuar"    
    read
}
