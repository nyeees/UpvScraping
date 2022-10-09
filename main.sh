#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Table
function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

trap ctrl_c INT
function helpPanel(){
	echo -e "\n ${grayColour}Panel de ayuda:${endColour}"
	echo -e "\n\t ${purpleColour}-n)${endColour} ${grayColour}Filtrar por notas${endColour}"
	echo -e "\n\t ${purpleColour}-a)${endColour} ${grayColour}Escoger un año ${endColour}"
	echo -e "\n\t ${purpleColour}-g)${endColour} ${grayColour}Obtener cookie a partir de usuario y contraseña. Ej:${endColour}(-g \"usuario contraseña\")"

}
function ctrl_c(){
	echo -e "${redColour}[!]Saliendo...${endColour}" 
	exit 1
}

function getCookie(){
	curl -X POST -d "id=c&estilo=500&vista=&param=&cua=miupv&dni=${userPass[0]}&clau=${userPass[1]}" "https://intranet.upv.es/pls/soalu/est_aute.intraalucomp" -c cookie.txt
	
	cookie=$(cat cookie.txt | grep "TDp" |awk 'NF{print$NF}')
	if [ "$cookie" ];then
		echo -e "\n${yellowColour}Advertencia[!]${endColour}${grayColour}: Se le va a proporcionar la cookie de sesion en breves, haz uso de ella con el parametro -c ${endColour}"
		sleep 3 

		echo -e "\n${grayColour}Cookie: ${endColour}${blueColour}$cookie${endColour}"
	else
		echo -e "\n${redColour}[!]${endColour} ${grayColour}Usuario o contraseña incorrecta${endColour}"

	fi
}

function notasInfo(){


	if [ "$year" == "all" ];then
		echo -e "Buscar por cualquier año"
	else
		echo -e "Buscas por el año ${year}"
	fi


	asignaturas=$(cat notas.txt | grep -i "Unica " -A 1 | grep -vE "Unic" | tr -d '0123456789' | tr -d '()')
	echo -e "${grayColour}"
	echo "Año_Asignatura_Nota_Percentil_Suspensos" > table.txt
	
	while read asignatura ;do 
		
		notaArray+=($(cat notas.txt | grep -m 1  "${asignatura}" -A 1 | tail -n 1 | awk '{print$4}'))
		percentilArray+=($(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$3}'))
		#suspensosArray+=($(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$7}'))
	done < asignaturas.txt
	
		IFS=$'\n' sortedNota=($(sort <<<"${notaArray[*]}"));
		IFS=$'\n' sortedPercentil=($(sort <<<"${percentilArray[*]}"));
		IFS=$'\n' sortedSuspensos=($(sort <<<"${suspensosArray[*]}"));
		unset IFS

		declare -i counter=0
		declare -i counterAsignatura=1

	while read asignatura ;do
		opcion=notas
	
		if [ "$opcion" == "notas" ];then	
			let counter+=1
			if [ "${sortedNota[counter]}" == ${sortedNota[counter-1]} ]; then
				let counterAsignatura+=1
			else
				let counterAsignatura=1
			fi
			miAsignatura=$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep -vE "\-|Unica" | tr -d '(0123456789)'| sed -n ${counterAsignatura}p)

			echo "$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep "^[[:digit:]]" | awk '{print$1}' | sed -n ${counterAsignatura}p)_$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep -vE "\-|Unica" | tr -d '(0123456789)'| sed -n ${counterAsignatura}p)_${sortedNota[counter]}_$(cat notas.txt | grep -i "$miAsignatura" -A 1 | tail -n 1 | awk '{print$3}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt
		#cat table.txt
	
		else
			
			echo "$(cat notas.txt | grep -m 1  "${asignatura}" -A 1 | tail -n 1 | awk '{print$1}')_${asignatura}_$(cat notas.txt | grep -m 1  "${asignatura}" -A 1 | tail -n 1 | awk '{print$4}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$3}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt
		fi
	done < asignaturas.txt
		
	printTable '_' "$(cat table.txt)"
	echo -e "${endColour}"
	rm miasignatura.txt
}


declare -i parameter_counter=0
while getopts "a:ng:c:h" arg; do
	case $arg in
		c)cookie_in=$OPTARG;;
		n)let parameter_counter+=2;;
		a)year=$OPTARG;;
		g)userPass=($OPTARG);let parameter_counter+=3;; #Escribe el nombre y contra entre ""
		h);;
	esac
done


if [ $parameter_counter -eq 2 ];then
	if [ "$cookie_in" ];then
		notasInfo
	else
		echo -e "${redColour}\nError ${endColour}${grayColour}Proporciona una cookie de sesion. Si no la tienes usa el parametro -g "
	fi
elif [ $parameter_counter -eq 3 ];then
	getCookie
else
	helpPanel
fi
