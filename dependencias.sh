#!/bin/bash

#Ultima Actualizacion NOV21

###
#Este script gestiona las dependencias necesarias
#para que el programa principal funcione correctamente
###

function dependInstalador(){
  instalador=$1
  #Recorremos el array y comprobamos si la aplicacióne stá instalada
    for app in "${paquetes[@]}"
    do
      check=$(whereis $app | awk '{print $2}')       
      if [ -z $check ] 
      then 
        #Si no está instalada, damos la opción de instalarla
        echo -e "$avisoR $app NO está instalada"
        echo -e "   ---------------------------------"
        echo -e "   Pulse I para instalar la app"
        echo -e "   Pulse ENTER para continuar sin instalar"
        echo -e "   ---------------------------------"
        read opc
        if [ "$opc" == "i" ] || [ "$opc" == "I" ]
        then
          #Comprobamos que existe conexión a Internet
          #nc -w 4 -z 8.8.8.8 53 1>/dev/null 2>>./Logs/error_$fecha.txt
          ping -c 6 8.8.8.8 1>/dev/null 2>>./Logs/error_$fecha.txt
          if [ $? -eq 0 ] 
          then
            if [[ "$app" == "route" ]]
            then
              $instalador net-tools 2>>./Logs/error_$fecha.txt
              #depend
            elif [[ "$app" == "ip" ]]
            then
              $instalador iproute2 2>>./Logs/error_$fecha.txt
              #depend
            elif [[ "$app" == "iwlist" ]] 
            then
              $instalador wireless-tools 2>>./Logs/error_$fecha.txt
              #depend
            elif [[ "$app" == "tracepath" ]]
            then
              $instalador iputils-tracepath 2>>./Logs/error_$fecha.txt
              #depend
            elif [[ ("$app" == "netdiscover") && ("$instalador" == "pacman -S") ]]
            then
              pamac build netdiscover
            elif [[ ("$app" == "tshark") && ("$instalador" == "pacman -S") ]]
            then
              pacman --noconfirm -Sy wireshark-qt
            else
              $instalador $app 2>>./Logs/error_$fecha.txt
              #depend
            fi
          else
            echo -e " $avisoR No dispone conexión a Internet"
            echo -e " $avisoR Imposible instalar dependencias"
            echo -e " $avisoR Finalizando programa..."
            echo -e "---------------------------------"
            exit 1
          fi
        else
          echo -e "$avisoA Sin las dependencias, ciertas funcionalidades no responderán correctamente"
          sleep 1
        fi
      else
        echo -e "$avisoV $app"
        sleep 0.1
      fi
    done
    echo -e ""  
    echo -e "$avisoV Iniciando el programa ..."  
    sleep 1
}

#Comprobamos los paquetes y dependencias necesarias para ejecutar el programa
function depend() { 
  clear 
  echo -e ""
  echo -e "$avisoV Comprobando dependencias..."
  echo -e "\n"

  #Array con el listado de dependencias necesarias
  declare -a paquetes=("aircrack-ng" "arp-scan" "ethtool" "ip" "iw" "iwlist" "macchanger" "netdiscover" "nmap" "route" "rfkill" "tcpdump" "tracepath" "tshark" "xterm") #"aa-complain" 
  
  instalador=$(whereis apt | awk '{print $2}')
  
  if [[ "/usr/bin/apt" == $instalador ]] #Sistemas DEBIAN
  then
    dependInstalador "apt install"
  else
    instalador=$(whereis pacman | awk '{print $2}')    
    if [[ "/usr/bin/pacman" == $instalador ]] #Sistemas ARCH
    then 
      dependInstalador "pacman --noconfirm -Sy"
    else
      echo -e "$avisoR Sistema no compatible"
      exit 0
    fi
  fi  

}
