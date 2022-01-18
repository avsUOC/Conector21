#!/bin/bash

#Ultima Actualizacion OCT21

###
#Este script gestiona las funciones relacionadas con la conexion
#y desconexion a redes inalambricas, asi como el estado, modos y reinicio
#de la tarjeta Wifi
###

#Avisos por colores
avisoV="\e[32m[*]\e[0m"
avisoA="\e[33m[->]\e[0m"
avisoR="\e[31m[!]\e[0m"
finCol="\e[0m"

#***************************************************Connection************************************************************
#*************************************************************************************************************************
#Este es el menú principal dentro de las opciones de conexiones.
#Aquí podemos conectarnos y desconectarnos de una red. Eliminar antiguas conexiones,
#agregar rutas de enrutado, invocar al menu de tarjeta que nos permite
#realizar cambios en la dirección MAC y el hostname, e
#inciar un escaneo wifi para ver las redes de los alrededores
function menuConexion() {
  clear
  estadoT
  echo -e "\e[45m ------------------------------------------------- \e[0m"
  echo -e "\e[45m               MENU - CONEXIÓN                     \e[0m"
  echo -e "\e[45m ------------------------------------------------- \e[0m"
  echo -e "\n"
  echo -e "\e[39m 1) Conectarse a una red\e[0m"
  echo -e "\e[39m 2) Desconectarse de una red\e[0m"
  echo -e "\e[39m 3) Eliminar una conexión anterior\e[0m"
  echo -e "\e[39m 4) Estado actual de las conexiones\e[0m"
  echo -e "\e[39m 5) Añadir ruta de enrutamiento\e[0m"
  echo -e "\e[39m 6) Opciones de tarjeta, MAC y Hostname\e[0m"
  echo -e "\e[39m 7) Escaneo WiFi\e[0m"  
  echo -e ""
  echo -e "\e[39m v) para volver al menú principal\e[0m"
  echo -e "\n"
  echo -e "\e[45m ------------------------------------------------- \e[0m"
  echo -e "\n"
  echo -ne "$avisoA"; read -r -p "  Introduzca una opción: " opc 
  case $opc in
    1)		
      conector
      killall nmcli 2>>/dev/null #Con este comando, eliminamos posibles instancias en segundo plano del comando nmcli.
      menuConexion 
    ;;

    2)
      disconector
      killall nmcli 2>>/dev/null
      menuConexion 
    ;;
    
    3)
      deletecon
      menuConexion 
    ;;

    4)
      conState
      killall nmcli 2>>/dev/null
      menuConexion 
    ;;
    
    5) 
      echo "2"
      enrutado     
      menuConexion 
    ;;

    6)
      menuTarjeta      
      menuConexion 
    ;;

    7)
      buscaWifi
      echo -e "$avisoA Pulse ENTER para continuar"
      read
      menuConexion 
    ;;

    v|V)
      menuPrincipal
    ;;

    *)
      menuConexion 
    ;;

  esac
}

#***************************************************Enrutado**************************************************************
#*************************************************************************************************************************

function enrutado() {
  clear
  connected=$(nmcli con show -a| grep -o $tarjetaWifi) #Comprobamos si la tarjeta está conectada a una red
  if [ "$tarjetaWifi" == "$connected" ]
  then 
    estadoT
    echo -e "\n"
    nmcli con show -a| grep -o $tarjetaWifi #Mostramos las conexiones activas de la tarjeta elegida
    echo -e "\n"
    ip=$(hostname -I)
    echo -e "$avisoV IP direction: $ip \n"
    echo -e "\n Si queremos llegar a otra red, debemos introducir los datos de enrutado y GW \n"  
    echo "Introduzca la direccion IP para el enrutado ej: 192.168.1.0/24"
    read enrutado
    if [ -z "$enrutado" ]
    then
      menuPrincipal
    fi
    echo -e "$avisoA Introduzca la direccion IP del GW ej: 192.168.68.1"
    read gatew
    sudo route add -net $enrutado gw $gatew dev $tarjetaWifi
    sudo ip route list
    echo -e "\n"
    echo -e "\e[39m-------------------------------------------------\e[0m"        
    echo -e "           Pulse ENTER para continuar"
    echo -e "\e[39m-------------------------------------------------\e[0m"
    read
  else
    echo -e "---------------------------------------------"
    echo -e "\e[5mFATAL: No está conectado a ninguna red \e[0m" 1>&2
    echo -e "---------------------------------------------"
    echo -e "\n"
    read
  fi
}

#***********************************************Escaneo Wifi**************************************************************
#*************************************************************************************************************************
function buscaWifi() {  
  fecha=$(date +'%d-%m-%Y') 
  hora=$(date +'%H:%M')
  mkdir ./Info/$fecha 2>/dev/null
  touch ./Info/$fecha/redes.txt 2>/dev/null
  if [ "$monitorEstado" == 1 ]
  then
    echo -e "$avisoA Tarjeta en modo monitor"
    normalT
  fi      
  #Buscamos las redes del entorno
  echo -e ""
  #Tiempo de búsqueda de redes wifi en segundos
  i=2   
  until [ $i -lt 0 ]
  do
    echo -e "$avisoV Buscando redes wifi... $i"    
    sudo nmcli dev wifi list ifname $tarjetaWifi | grep -v IN-USE >> ./Info/$fecha/redes.txt
    sleep 1
    ((i--))
  done
  clear
  echo -e "$avisoV Redes detectadas \n"
  echo -e "IN-USE  BSSID              SSID                 MODE   CHAN  RATE        SIGNAL  BARS  SECURITY " > ./Info/$fecha/redes_$hora.txt
  echo -e "" >> ./Info/$fecha/redes_$hora.txt
  grep -v IN-USE ./Info/$fecha/redes.txt |sort|uniq >> ./Info/$fecha/redes_$hora.txt
  cat ./Info/$fecha/redes_$hora.txt
  rm ./Info/$fecha/redes.txt
  echo -e ""
}

#***************************************************Conexión**************************************************************
#*************************************************************************************************************************

function conector() {
  clear
  #rm ./Info/redesWifi.txt 2>/dev/null
  connected=$(nmcli con show -a| grep -o $tarjetaWifi) #obtenemos el estado de la conexión, si está conectado o no a una red
  #Se comprueba que la tarjeta se encuentre en modo managed
  if [ "$monitorEstado" == 1 ]
  then
    echo -e ""    
    echo -e "\e[31m[!][!]\e[0m La tarjeta debe estar en modo Managed"
    echo -e "\e[31m[!][!]\e[0m Utilice el menú tarjeta para ello"
    echo -e ""
    echo -e "\e[33m[*][*]\e[0m Pulse ENTER para continuar"
    read
  #Se comprueba si ya está conectado a una red
  elif [[ "$tarjetaWifi" == "$connected" ]]
  then
    echo -e ""
    echo -e "\e[31m[!][!]\e[0m Ya está conectado a una red"
    echo -e ""
    echo -e "\e[33m[*][*]\e[0m Pulse ENTER para continuar"
    read    
  #Posibilidad de cambiar dirección MAC  
  else
    estadoT 
    echo -e "$avisoA Se recomienda cambiar la MAC de conexión"
    echo -e ""
    echo -ne "$avisoA ¿Cambiar MAC? Si/No: "; read opc
    echo -e ""    
    if [ "$opc" == "s" ] || [ "$opc" == "S" ]
    then
      menuMAC
      echo -e ""
      echo -e "$avisoV Configurando la tarjeta...¡Espere unos segundos!"
      echo -e ""   
      sleep 2
    fi
    clear
    #Posibilidad de cambiar Hostname
    estadoT    
    echo -e "$avisoV Se recomienda cambiar el Hostname del equipo"
    echo -e ""
    echo -ne "$avisoA ¿Cambiar Hostname? Si/No: "; read opc
    echo -e ""    
    if [ "$opc" == "s" ] || [ "$opc" == "S" ]
    then
      menuHostname
      echo -e "$avisoV Configurando la tarjeta...¡Espere unos segundos!"
      echo -e ""
      sleep 2
    fi
    clear
    #menuConexion  
    estadoT          
    #Buscamos las redes del entorno
    buscaWifi

    #Muestra conexiones guardadas
    echo -e ""
    echo -e "$avisoV Conexiones guardadas anteriormente"
    nmcli conn show | grep wifi
    echo -e ""
    encontrado=$(cat ./Info/$fecha/redes_$hora.txt | grep -v "IN-USE" | sort | uniq)
    if [ -z "$encontrado" ]
    then
        echo -e "$avisoR No se han encontrado redes Wifi en el entorno"
        echo -e "$avisoA Pulse ENTER para continuar"
        read
    else        
        echo -e ""     
        echo -ne "$avisoA Introduzca el nombre de la red WIFI: "; read red
        if [[ -z "$red" ]] || [[ -z "$(grep $red ./Info/$fecha/redes_$hora.txt | sort | uniq)" ]]
        then
          echo -e "$avisoR Red errónea"
          sleep 2
          menuConexion
        fi
        echo -e "$avisoA Introduzca la clave WiFi: "; read clave
        sudo killall nmcli 2>>./Logs/eliminaConexion_$fecha.txt
        sudo nmcli connection delete "$red" 2>>./Logs/eliminaConexion_$fecha.txt
        sleep 1
        clear
        sudo killall nmcli 2>>./Logs/eliminaConexion_$fecha.txt
        clear
        echo -e "$avisoV Estableciendo conexión..."
        echo -e ""
        sudo nmcli d wifi connect "$red" password $clave ifname $tarjetaWifi 2>>./Logs/creaConexion_$fecha.txt
        sleep 1
        sudo nmcli con mod "$red" connection.autoconnect no 2>>./Logs/creaConexion_$fecha.txt
        echo -e "\n"  
        sudo ip route list 2>>./Logs/ipRoute_$fecha.txt
        echo -e ""
        #Comprobamos que se ha conectado correctamente
        if [[ "$(nmcli con show -a |grep -o $red)" == "$red" ]]
        then
          echo -e "$avisoV Conexiones ACTIVAS"        
          echo -e " --------------------------------------------------------- "
          nmcli con show -a          
          echo -e ""
          echo -e "$avisoV IPs ACTIVAS"        
          echo -e " --------------------------------------------------------- "
          hostname -I | tr -s '[:blank:]' '\n'                  
          echo -e ""        
          echo -e "$avisoV ¿Añadir enrutamiento adicional?. Si/No."
          read opc
          if [ "$opc" == "s" ] || [ "$opc" == "S" ]
          then
            echo -e "\n Si queremos llegar a otra red, debemos introducir los datos de enrutado y GW \n"	
            echo -e "$avisoA Introduzca la direccion IP para el enrutado ej: 192.168.1.0/24"
            read enrutado
            echo -e "$avisoA Introduzca la direccion IP del GW ej: 192.168.68.1"
            read gatew
            sudo route add -net $enrutado gw $gatew dev $tarjetaWifi
            echo -e "\n"
            sudo ip route list
            echo -e "\n"
            echo -e "\e[39m ------------------------------------------------- \e[0m"        
            echo -e "            Pulse ENTER para continuar"
            echo -e "\e[39m ------------------------------------------------- \e[0m"
            read
          fi
        else
          echo -e ""
          echo -e "\e[31m[!][!]\e[0m No se ha podido conectar"
          sleep 2
        fi
    fi
    
    #echo -e "\n ¿Abrir navegador al ROUTER?, Si/No "
    #read opc
    opc="n"
    if [ "$opc" == "s" ] || [ "$opc" == "S" ]
    then
      echo -e "$avisoA Introduzca la IP del Router"
      read puerta
      #firefox 192.168.1.1 -no-remote -no-xshm
      su valcuero firefox $puerta
      su -c 'chromium $puerta'
      clear
      #killall firefox
    fi
  fi
}

#************************************************Desconexión**************************************************************
#*************************************************************************************************************************

#function menu_disconect() {
#  echo -e "\e[45m ------------------------------------------------- \e[0m"
#  echo -e "\e[45m                Desconexión de Red                 \e[0m"
#  echo -e "\e[45m ------------------------------------------------- \e[0m"
#  echo -e "\n"
#}

function disconector() {
  clear
  connected=$(nmcli con show -a|grep $tarjetaWifi)
  if [[ -n "$connected" ]]
  then
    echo -e "$avisoV Conexiones Activas"
    echo -e "NAME                UUID                                  TYPE      DEVICE "
    nmcli con show -a |grep wifi
    echo -e "\n"
    echo -e "$avisoV Indique el nombre o el UUID de la red a desconectar"
    read desco
    if [ -z "$desco" ]
    then
      menuPrincipal    
    elif [[ $(nmcli con show $desco 2>/dev/null |wc -l) -lt 1 ]]
    then
      echo -e ""
      echo -e "\e[31m[!][!]\e[0m No existe la conexión $desco"
      echo -e "\e[31m[!][!]\e[0m Pulse ENTER para continuar"
      read    
      menuConexion 
    fi
    echo -e ""
    sudo nmcli con down "$desco" 2>>./Logs/downConexion_$fecha.txt
    echo -e "\n"
    echo -e "-------------------------------------------------"
    echo -e "$avisoA ¿Elmiminar la conexión permanentemente?. Si/No"    
    echo -e "-------------------------------------------------"
    read opc
    if [ "$opc" == "s" ] || [ "$opc" == "S" ]
    then
      sudo nmcli con delete "$desco" 2>>./Logs/eliminaConexion_$fecha.txtl
      sleep 1  
    fi 
    sudo killall nmcli 2>>./Logs/creaConexion_$fecha.txt
  else
    echo -e "\e[31m[!][!]\e[0m FATAL: No está conectado a ninguna red Wifi" 1>&2
    echo -e "\n"
    read
  fi
}

#**************************************************Eliminación************************************************************
#*************************************************************************************************************************

function deletecon() {
  clear
  connected=$(nmcli con show -a|grep -o $tarjetaWifi)
  if [[ -z "$connected" ]]
  then
    echo -e "\e[39m    Se pueden eliminar conexiones anteriores       \e[0m" 1>&2
    echo -e "\n"
  fi
  if [[ -z "$(nmcli con show|grep wifi)" ]]
  then
    echo -e "\e[31m[!][!]\e[0m No existen conexiones guardadas"
    sleep 2
    menuPrincipal
  fi
  echo -e "$avisoV Conexiones Guardadas WIFI               "
  nmcli con show|grep wifi
  echo -e "\n"
  echo -e "$avisoA Selecione la red para eliminar, columna "NAME" "
  read desco
  if [[ -z "$desco" ]]
  then
    echo -e "$avisoR Red errónea"
    sleep 2
    menuPrincipal
  fi
  echo ""
  sudo nmcli con down "$desco" 2>>./Logs/downConexion_$fecha.txt
  sudo nmcli con delete "$desco" 2>>./Logs/eliminaConexion_$fecha.txt
  echo -e "$avisoV Conexión $desco eliminada"
  sleep 1  
  sudo killall nmcli 2>>./Logs/killConexion_$fecha.txt  
}

#***********************************************Estado coneciones*********************************************************
#*************************************************************************************************************************


function conState() {
  clear
  echo -e "\n"
  echo -e "$avisoV CONEXIONES ACTIVAS (TODAS) \n"
  echo -e " --------------------------------------------------------- "
  echo -e " $(nmcli con show -a )"
  red=$(nmcli con show -a| cut -d' ' -f1| sed '2q;d')  
  echo -e "\n"
  echo -e "$avisoV DIRECCIONES IP ASIGNADAS (TODAS) \n"  
  echo -e " --------------------------------------------------------- "
  hostname -I | tr -s '[:blank:]' '\n'  
  echo -e "\n"
  echo -e "$avisoV DIRECCIONES IP TARJETA $tarjetaWifi \n"
  echo -e " --------------------------------------------------------- "
  ip route show | grep $tarjetaWifi  
  echo -e "\n"
  echo -e "$avisoA Pulse ENTER para continuar"
  read
}
