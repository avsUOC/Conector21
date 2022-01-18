#!/bin/bash

#Ultima Actualizacion DIC21

###
#Este script gestiona las conexiones de redes inalámbricas 
#También permite modificar las caracteristicas de la tarjetaWifi de red WiFi y cambiar el modo de trabajo
#Por otro lado, hace posible realizar capturas de tráfico así como un pequeño análisis de estas
#Al estar conectados a una red, se puede recopilar información y realizar un levantamiento de equipos
#Por último, el script es capaz de realizar un escaneo del aire
###

#set -o errexit #El script finaliza si se produce algún error
#set -o pipefail #El script finaliza si se produce algún error en pipe
#set -o nounset #El script finaliza si se usa una variable no declarada
#set - o xtrace #Modo debug


#Avisos por colores
avisoV="\e[32m[**]\e[0m"
avisoA="\e[33m[->]\e[0m"
avisoR="\e[31m[!!]\e[0m"
finCol="\e[0m"


#***************************************************menuPrincipal*************************************************************************
#***********************************************************************************************************************************
#Función principal, donde se inicializan variables y se muestra el menu general
function menuPrincipal()  {
  clear
  #Obtenemos el estado de la tarjeta wifi
  estadotarjetaWifi=$(iw dev $tarjetaWifi info | grep type | cut -d' ' -f2)
  if [[ "$estadotarjetaWifi" == "managed" ]]
  then
    monitorEstado=0
  else
    monitorEstado=1
  fi  
  export monitorEstado  
  #Mostramos la ventana de estado
  estadoT
  #Menú principal  
  echo -e "\e[44m ------------------------------------------------- \e[0m"
  echo -e "\e[44m                MENU - PRINCIPAL                   \e[0m"
  echo -e "\e[44m ------------------------------------------------- \e[0m"
  echo -e "\n"
  echo -e "\e[39m 1) Opciones \e[44m TARJETA \e[0m\e[0m"  
  echo -e "\e[39m 2) Opciones \e[35m CONEXION \e[0m\e[0m"
  echo -e "\e[39m 3) Opciones \e[33m ANALISIS \e[0m\e[0m"
  echo -e "\e[39m 4) Opciones \e[32m CAPTURA \e[0m\e[0m"
  echo -e "\e[39m 5) Opciones \e[31m ATAQUES \e[0m\e[0m"
  echo -e ""
  echo -e "\e[39m 6) Listar capturas anteriores\e[0m"
  echo -e "\e[39m 7) Listar análisis anteriores\e[0m"
  echo -e "\n"
  echo -e "   \e[44m Pulse s para Salir de forma correcta \e[0m"  
  echo -e "\n"
  echo -e "\e[44m ------------------------------------------------- \e[0m\n"
  read -r -p "     Introduzca una opción: " opc
  case $opc in
    1)		
      menuTarjeta      
      menuPrincipal
    ;;

    2)
      menuConexion       
      menuPrincipal
    ;;

    3)
      menuAnalisis
      menuPrincipal
    ;;    

    4)
      menuCaptura      
      menuPrincipal
    ;;

    5)
      menuAttack 
      menuPrincipal
    ;;
      
    6)
      #Se comprueba si la carpeta está vacía
      if [ "$(ls ./Capturas/)" ]
      then
        echo -e ""
        echo -e "$avisoV Carpetas"        
        ls ./Capturas/ | nl
        echo -e ""
        echo -e "$avisoV Ficheros"
        ls -lah ./Capturas/* |grep pcap | awk '{print $5,$9}' | column -t | nl 2>/dev/null
        echo -e ""
      else
        echo -e "\n"
        echo -e "$avisoA Directorio Vacío"
        sleep 2
        menuPrincipal
      fi 
      #Se eliminan posibles ficheros antiguos tras comprobar que el directorio no está vacio
      echo -e " ---------------------------------------- "
      echo -e "¿Desea eliminar las carpetas y su contenido?. Si/No"
      echo -e " --------------------------------------- "
      echo -ne "$avisoA Introduzca una opción: ";read opc
      if [ "$opc" == "S" ]
      then
          rm -Rf ./Capturas/* 2>> ./Logs/$fecha/errores_$hora.txt
          echo -e "$avisoA Capturas eliminadas"
          sleep 2
          echo -e ""
      fi      
      menuPrincipal
    ;;

    7)
      #Se comprueba si la carpeta está vacía
      if [ "$(ls ./Info/)" ]
      then
        echo -e ""
        echo -e "$avisoV  Carpetas de análisis anteriores: "
        ls ./Info/* | nl 2>/dev/null
        echo -e ""
      else
        echo -e "\n"
        echo -e "$avisoA Directorio Vacío"
        sleep 2
        menuPrincipal
      fi 
      #Se eliminan posibles ficheros antiguos tras comprobar que el directorio no está vacio
      echo -e " ---------------------------------------- "
      echo -e "¿Desea eliminar las carpetas y su contenido?. Si/No"
      echo -e " --------------------------------------- "
      echo -ne "$avisoA Introduzca una opción: ";read opc
      if [ "$opc" == "S" ]
      then
          rm -Rf ./Info/* 2>> ./Logs/$fecha/errores_$hora.txt
          echo -e "$avisoA Archivos eliminados"
          sleep 2
          echo -e ""
      fi      
      menuPrincipal
    ;;    

    s|S)
      salir
    ;;

    *)
      clear
      menuPrincipal
    ;;

  esac
}

#Funcion para salir completamente del programa
function salir(){
  clear
  connected=$(nmcli con show -a| grep -o $tarjetaWifi)
  if [ "$tarjetaWifi" == "$connected" ]
  then  
    echo -e "-------------------------------------------------"                          
    echo -e "Está conectado a una red, ¿desea desconectarse?"
    echo -e "                  Si/No"
    echo -e "-------------------------------------------------"
    read opc
    if [ "$opc" == "s" ] || [ "$opc" == "S" ]
    then
      disconector
      sudo nmcli radio wifi off 2>> ./Logs/$fecha/errores_$hora.txt
      sleep 1
      sudo nmcli radio wifi on 2>> ./Logs/$fecha/errores_$hora.txt
    else
      clear
      exit 1          
    fi        
  fi
  clear
  exit 1
}

#Ventana de estado
function estadoT() {
  echo -e "\e[46m ------------------------------------------------- \e[0m"
  echo -e "\e[46m     Estado de la tarjeta y del Equipo             \e[0m"
  echo -e "\e[46m ------------------------------------------------- \e[0m"
  comand=$(iw $tarjetaWifi info | grep -e Interface -e addr -e ssid -e type -e channel -e txpower )
  conectado=$(iw $tarjetaWifi info | grep ssid)
  echo -e " "
  echo -e "$avisoV $comand \n"
  echo -e "$avisoV Canales aceptados por la tarjeta: $tarjetaWifi " 
  
  #Imprimimos los canales en dos filas
  for (( i=0; i<$lenCanales/2; i++ )); do 
    echo -en " ${canalesIW[$i]}"
  done
  echo -e ""
  for (( i=$lenCanales/2; i<$lenCanales; i++ )); do 
    echo -en " ${canalesIW[$i]}"
  done
  echo -e ""
  
  nombrehost=$(hostname)
  echo -e " "
  echo -e "$avisoV  Sistema:  $(lsb_release -d |awk '{print $2,$3,$4}')"
  echo -e "$avisoV  Hostname: $nombrehost"  
  echo -e " "
  if [[ -n $conectado ]]
  then
    echo -e "$avisoV  El equipo está conectado a la red: $(iw $tarjetaWifi info|grep ssid| cut -d' ' -f2)"
    echo -e "\n"
  fi
  echo -e "\e[46m ------------------------------------------------- \e[0m"
  echo -e ""
  echo -e "$avisoV CONECTOR - SUITE DE GESTIÓN DE REDES WIFI - V1.1"
  echo -e ""
}

#Detectar tarjeta de red
function detectCard() {
  cardsIW=$(iw dev|grep -i interface|column -t| awk '{print $2}'|grep -v -i interface)
  if [[ -n $cardsIW ]]
  then
    echo -e "$avisoV Tarjetas Wi-Fi detectadas:"
    echo -e " \e[32m         |\e[0m"    
    echo -e " \e[32m         V\e[0m"    
    for app in $cardsIW
    do
      iw dev $app info|column -t|egrep -e Interface -e addr
    done     
    echo -e " ---------------------------------"
    echo -e "\n"
  else
    echo -e "No se han detectado tarjetas inalámbricas"
    echo -e ""
  fi
}

#***************************************************INICIO del PROGRAMA*************************************************************
#***********************************************************************************************************************************

clear 
#Guardamos la fecha de ejecución
fecha=$(date +'%d-%m-%Y')
hora=$(date +'%H:%M') 
#Comprobamos si la llamada del script es la correcta
#¿Tiene argumento?
if [ -z "$1" ]
then
  echo -e ""
  echo -e "$avisoV CONECTOR - SUITE DE GESTIÓN DE REDES WIFI - V1.1"
  echo -e ""
  echo -e "$avisoV Argumentos requeridos:"
  echo -e "       $avisoA tarjeta Wifi"
  echo -e ""
  echo -e "$avisoV Ejemplo:"
  echo -e "       $avisoV sudo ./Conector.sh wlan0"
  echo -e "" 
  detectCard   
else
  tarjetaWifi=$1
  
  export tarjetaWifi

  #Incluimos algunos scripts de los distintos módulos
  source notificaciones.sh
  source dependencias.sh

  #Comprobamos si se ha ejecutado con privilegios de root
  if [ $(noRoot) = 1 ]
  then
    echo -e " -------------------------------------------------------------- "
    echo -e " $avisoR$avisoR ERROR: debe ejecutar el programa con privilegios root"
    echo -e " -------------------------------------------------------------- "
    echo -e "\n"
    exit 1
  else
    #Activamos la tarjetaWifi wifi
    sudo nmcli radio wifi on 2>/dev/null
    #Se crean las carpetas y ficheros si es necesario
    mkdir ./Info 2>/dev/null
    mkdir ./Logs 2>/dev/null
    mkdir ./Logs/$fecha 2>/dev/null
    mkdir ./Capturas 2>/dev/null
    touch ./Logs/$fecha/errores_$hora.txt 2>/dev/null
    
    #Eliminamos registros anteriores    
    #rm ./Info/redes.txt 2>/dev/null
    
    #Se habilita forwarding
    sudo echo "1" > /proc/sys/net/ipv4/ip_forward       
    #Se comprueba que la tarjetaWifi elegida existe
    if [ "$(noCard $tarjetaWifi)" == "1" ]
    then
      echo -e " ---------------------------------------------------- "
      echo -e " \e[31m [!][!]\e[0m ERROR: La tarjeta '$tarjetaWifi' no existe"
      echo -e " ---------------------------------------------------- "               
      detectCard      
      exit 0
    else
      
      #Comprobamos si las dependencias están instaladas
      depend      

      #Incluimos el resto de scripts de los módulos
      source canales.sh
      source analisis.sh
      source ataques.sh
      source captura.sh
      source connections.sh
      source deauth.sh 
      source tarjeta.sh
      #Configuramos tcpdump
      aa-complain /usr/sbin/tcpdump 2>> ./Logs/$fecha/errores_$hora.txt
      #Configuramos rfkill
      rfkill unblock all 2>> ./Logs/$fecha/errores_$hora.txt
      clear  
      #Llamada al Menú principal      
      menuPrincipal
    fi    
  fi  
fi
