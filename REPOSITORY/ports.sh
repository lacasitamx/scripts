#!/bin/bash
declare -A cor=( [0]="\033[33m" [1]="\033[33m" [2]="\033[33m" [3]="\033[33m" [4]="\033[33m" )
barra="\033[0m\e[33m======================================================\033[1;37m"
#script, cambiar puerto
msg () {
BRAN='\033[33m' && VERMELHO='\e[31m'
VERDE='\e[33m' && AMARELO='\e[33m'
AZUL='\e[33m' && MAGENTA='\e[35m'
MAG='\033[33m' && NEGRITO='\e[1m'
SEMCOR='\e[0m'
 case $1 in
  -ne)cor="${VERMELHO}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -ama)cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm)cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}";;
  -azu)cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verd)cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bra)cor="${BRAN}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  "-bar2"|"-bar")cor="${AZUL}======================================================" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
 esac
}
puertos_pro(){
local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
local NOREPEAT
local reQ
local Port
while read port; do
reQ=$(echo ${port}|awk '{print $1}')
Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
[[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
NOREPEAT+="$Port\n"
case ${reQ} in
squid|squid3)
[[ -z $SQD ]] && local SQD="\033[1;36m➫ \e[1;37mSQUID:\033[1;32m"
SQD+="$Port ";;
apache|apache2)
[[ -z $APC ]] && local APC="\033[1;36m➫ \e[1;37mAPACHE:\033[1;32m"
APC+="$Port ";;
ssh|sshd)
[[ -z $SSH ]] && local SSH="\033[1;36m➫ \e[1;37mSSH:\033[1;32m"
SSH+="$Port ";;
dropbear)
[[ -z $DPB ]] && local DPB="\033[1;36m➫ \e[1;37mDROPBEAR:\033[1;32m"
DPB+="$Port ";;
nc.tradit)
[[ -z $GEN ]] && local GEN="\033[1;36m➫ \e[1;37mKEYGEN:\033[1;32m"
GEN+="$Port ";;
openvpn)
[[ -z $OVPN ]] && local OVPN="\033[1;36m➫ \e[1;37mOPENVPN-TCP:\033[1;32m"
OVPN+="$Port ";;
esac
done <<< "${portasVAR}"
#UDP
local portasVAR=$(lsof -V -i -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND")
local NOREPEAT
local reQ
local Port
while read port; do
reQ=$(echo ${port}|awk '{print $1}')
Port=$(echo ${port} | awk '{print $9}' | awk -F ":" '{print $2}')
[[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
NOREPEAT+="$Port\n"
case ${reQ} in
openvpn)
[[ -z $OVPN ]] && local OVPN="\033[0;36m➫ OPENVPN-UDP:\033[1;32m"
OVPN+="$Port ";;
esac
done <<< "${portasVAR}"
[[ ! -z $SSH ]]
echo -e $SSH
[[ ! -z $DPB ]]
echo -e $DPB
[[ ! -z $OVPN ]]
echo -e $OVPN
[[ ! -z $SQD ]]
echo -e $SQD
[[ ! -z $APC ]]
echo -e $APC
[[ ! -z $GEN ]]
echo -e $GEN
msg -bar2
}
port () {
local portas
local portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
i=0
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e ${portas}|grep -w "$var1 $var2")" ]] || {
    portas+="$var1 $var2 $portas"
    echo "$var1 $var2"
    let i++
    }
done <<< "$portas_var"
}
verify_port () {
local SERVICE="$1"
local PORTENTRY="$2"
[[ ! $(echo -e $(port|grep -v ${SERVICE})|grep -w "$PORTENTRY") ]] && return 0 || return 1
}
edit_squid () {
msg -azu "REDEFINIR PUERTAS SQUID"
msg -bar
if [[ -e /etc/squid/squid.conf ]]; then
local CONF="/etc/squid/squid.conf"
elif [[ -e /etc/squid3/squid.conf ]]; then
local CONF="/etc/squid3/squid.conf"
fi
NEWCONF="$(cat ${CONF}|grep -v "http_port")"
msg -ne "SU NUEVA PUERTA: "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port squid "${PTS}" && echo -e "\033[1;33mPUERTA $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPUERTA $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
 if [[ "${varline}" = "#portas" ]]; then
  for NPT in $(echo ${newports}); do
  echo -e "http_port ${NPT}" >> ${CONF}
  done
 fi
done <<< "${NEWCONF}"
msg -azu "ESPERE UN MOMENTO"
service squid restart &>/dev/null
service squid3 restart &>/dev/null
sleep 1s
msg -bar
msg -azu "PUERTAS REDEFINIDAS"
msg -bar
}
edit_apache () {
msg -azu "REDEFINIR PUERTAS APACHE"
msg -bar
local CONF="/etc/apache2/ports.conf"
local NEWCONF="$(cat ${CONF})"
msg -ne "SU NUEVO PUERTO SERIA?: "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port apache "${PTS}" && echo -e "\033[1;33mPUERTA $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPUERTA $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
if [[ $(echo ${varline}|grep -w "Listen") ]]; then
 if [[ -z ${END} ]]; then
 echo -e "Listen ${newports}" >> ${CONF}
 END="True"
 else
 echo -e "${varline}" >> ${CONF}
 fi
else
echo -e "${varline}" >> ${CONF}
fi
done <<< "${NEWCONF}"
msg -azu "ESPERE UN MOMENTO"
service apache2 restart &>/dev/null
sleep 1s

msg -bar
msg -azu "PUERTAS REDEFINIDAS"
msg -bar
}
edit_openvpn () {
msg -azu "REDEFINIR PUERTA OPENVPN"
msg -bar
local CONF="/etc/openvpn/server.conf"
local CONF2="/etc/openvpn/client-common.txt"
local NEWCONF="$(cat ${CONF}|grep -v [Pp]ort)"
local NEWCONF2="$(cat ${CONF2})"
msg -ne "SU NUEVO PUERTO ES?: "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port openvpn "${PTS}" && echo -e "\033[1;33mPUERTA $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPUERTA $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
if [[ ${varline} = "proto tcp" ]]; then
echo -e "port ${newports}" >> ${CONF}
fi
done <<< "${NEWCONF}"
rm ${CONF2}
while read varline; do
if [[ $(echo ${varline}|grep -v "remote-random"|grep "remote") ]]; then
echo -e "$(echo ${varline}|cut -d' ' -f1,2) ${newports} $(echo ${varline}|cut -d' ' -f4)" >> ${CONF2}
else
echo -e "${varline}" >> ${CONF2}
fi
done <<< "${NEWCONF2}"
msg -azu "ESPERE"
service openvpn restart &>/dev/null
/etc/init.d/openvpn restart &>/dev/null
sleep 1s

msg -bar
msg -azu "PUERTAS REDEFINIDAS"
msg -bar
}
edit_dropbear () {
msg -azu "REDEFINIR PUERTAS DROPBEAR"
msg -bar
local CONF="/etc/default/dropbear"
local NEWCONF="$(cat ${CONF}|grep -v "DROPBEAR_EXTRA_ARGS")"
msg -ne "SU NUEVO PUERTO ES?: "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port dropbear "${PTS}" && echo -e "\033[1;33mPUERTA $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPUERTA $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
 if [[ ${varline} = "NO_START=0" ]]; then
 echo -e 'DROPBEAR_EXTRA_ARGS="VAR"' >> ${CONF}
 for NPT in $(echo ${newports}); do
 sed -i "s/VAR/-p ${NPT} VAR/g" ${CONF}
 done
 sed -i "s/VAR//g" ${CONF}
 fi
done <<< "${NEWCONF}"
msg -azu "ESPERE"
service dropbear restart &>/dev/null
sleep 1s

msg -bar
msg -azu "PUERTAS REDEFINIDAS"
msg -bar
}
edit_openssh () {
msg -azu "REDEFINIR PUERTAS OPENSSH"
msg -bar
local CONF="/etc/ssh/sshd_config"
local NEWCONF="$(cat ${CONF}|grep -v [Pp]ort)"
msg -ne "SU NUEVO PUERTO ES: "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port sshd "${PTS}" && echo -e "\033[1;33mPUERTA $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPUERTA $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
for NPT in $(echo ${newports}); do
echo -e "Port ${NPT}" >> ${CONF}
done
while read varline; do
echo -e "${varline}" >> ${CONF}
done <<< "${NEWCONF}"
msg -azu "ESPERE"
service ssh restart &>/dev/null
service sshd restart &>/dev/null
sleep 1s

msg -bar
msg -azu "PUERTAS REDEFINIDAS"
msg -bar
}
puertos_pro
main_fun () {
unset newports
i=0
while read line; do
let i++
          case $line in
          squid|squid3)squid=$i;; 
          apache|apache2)apache=$i;; 
          openvpn)openvpn=$i;; 
          dropbear)dropbear=$i;; 
          sshd)ssh=$i;; 
          esac
done <<< "$(port|cut -d' ' -f1|sort -u)"
for((a=1; a<=$i; a++)); do
[[ $squid = $a ]] && echo -ne "\033[1;32m [$squid] > " && msg -azu "CAMBIAR PUERTA SQUID"
[[ $apache = $a ]] && echo -ne "\033[1;32m [$apache] > " && msg -azu "CAMBIAR PUERTA APACHE"
[[ $openvpn = $a ]] && echo -ne "\033[1;32m [$openvpn] > " && msg -azu "CAMBIAR PUERTA OPENVPN"
[[ $dropbear = $a ]] && echo -ne "\033[1;32m [$dropbear] > " && msg -azu "CAMBIAR PUERTA DROPBEAR"
[[ $ssh = $a ]] && echo -ne "\033[1;32m [$ssh] > " && msg -azu "CAMBIAR PUERTA SSH"
done
echo -ne "\033[1;32m [0] > " && msg -azu "VOLVER"
echo -e "$barra"
while true; do
echo -ne "\033[1;37mSELECIONE UNA OPCION: " && read selection
tput cuu1 && tput dl1
[[ ! -z $squid ]] && [[ $squid = $selection ]] && edit_squid && break
[[ ! -z $apache ]] && [[ $apache = $selection ]] && edit_apache && break
[[ ! -z $openvpn ]] && [[ $openvpn = $selection ]] && edit_openvpn && break
[[ ! -z $dropbear ]] && [[ $dropbear = $selection ]] && edit_dropbear && break
[[ ! -z $ssh ]] && [[ $ssh = $selection ]] && edit_openssh && break
[[ "0" = $selection ]] && break
done
#exit 0
}
main_fun
