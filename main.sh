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
	echo -e "\n\t ${purpleColour}-g)${endColour} ${grayColour}Obtener cookie a partir de DNI y contraseña. Ej:(${purpleColour}-g${endColour}${grayColour} \"89103629 8901\")${endColour}"
	echo -e "\n\t ${purpleColour}-c)${endColour} ${grayColour}Introducir cookie. Ej: (${purpleColour}-c${endColour}${grayColour} "103122b.90184bd2")${endColour}"
	echo -e "\n\t ${purpleColour}-n)${endColour} ${grayColour}Filtrar por notas${endColour}"
	echo -e "\n\t ${purpleColour}-o)${endColour} ${grayColour}Ordenar notas por criterio (${yellowColour}nota${endColour}${grayColour}/${yellowColour}año${endColour}${grayColour}/${endColour}${yellowColour}suspendidos${endColour}${grayColour}/${endColour}${yellowColour}percentil${endColour}${grayColour}). Ej: (${purpleColour}-c${endColour}${grayColour} "103122b.90184bd2"${endColour}${purpleColour} -n -o ${endColour}${grayColour}suspendidos)${endColour}"
	echo -e "\n\t ${purpleColour}-a)${endColour} ${grayColour}Escoger un año ${endColour}${grayColour}. Ej: (${purpleColour}-c${endColour}${grayColour} "103122b.90184bd2"${endColour}${purpleColour} -n -a ${endColour}${grayColour}2021)${endColour}"
	echo -e "\n\t ${purpleColour}-m)${endColour} ${grayColour}Analizar una asignatura ${endColour}${grayColour}. Ej: (${purpleColour}-c${endColour}${grayColour} "103122b.90184bd2"${endColour}${purpleColour} -m ${endColour}${grayColour}"Física I")\n${endColour}"


}
function ctrl_c(){
	echo -e "${redColour}[!]Saliendo...${endColour}" 
	(rm miasignatura.txt  asignaturas.txt notas.txt table.txt cookie.txt )  2>/dev/null
	exit 1
}

function getCookie(){
	curl -X POST -d "id=c&estilo=500&vista=&param=&cua=miupv&dni=${userPass[0]}&clau=${userPass[1]}" "https://intranet.upv.es/pls/soalu/est_aute.intraalucomp" -c cookie.txt
	
	cookie=$(cat cookie.txt | grep "TDp" |awk 'NF{print$NF}')
	if [ "$cookie" ];then
		echo -e "\n${yellowColour}Advertencia[!]${endColour}${grayColour}: Se le va a proporcionar la cookie de sesión en breves, haz uso de ella con el parametro -c ${endColour}"
		sleep 3 

		echo -e "\n${grayColour}Cookie: ${endColour}${blueColour}$cookie${endColour}"
	else
		echo -e "\n${redColour}[!]${endColour} ${grayColour}Usuario o contraseña incorrecta${endColour}"

	fi
	(rm cookie.txt) 2>/dev/null 
}

function notasInfo(){


	cat notas.txt | grep "Unica " -B 1 | grep -v "Uni" | tr -d '(0123456789)' > asignaturas.txt
	if [ "$option" == "nota" ];then

		echo -e "\n\t${grayColour}A continuación se ordenará por ${endColour}${yellowColour}nota${endColour}"
	elif [ "$option" == "percentil" ];then
		echo -e "\n\t${grayColour}A continuación se ordenará por ${endColour}${yellowColour}percentil ${endColour}"
	elif [ "$option" == "suspendidos" ];then
		echo -e "\n\t${grayColour}A continuación se ordenará por ${endColour}${yellowColour}suspendidos${endColour}"
	elif [ "$option" == "año" ];then
                  echo -e "\n\t${grayColour}A continuación se ordenará por ${endColour}${yellowColour}año${endColour}"	
	elif [ "$option" ];then
		echo -e "\n\t${grayColour}Opción incorrecta${endColour}\n"
		ctrl_c
	else
		echo -e "\n\t${grayColour}A continuación se mostrarán las asignaturas del año ${endColour}${yellowColour}${year}${endColour}"
		cat notas.txt | grep "${year}  Unica" -B 1 | grep -v "Uni" | tr -d '(0123456789)' > asignaturas.txt
	fi

	asignaturas=$(cat notas.txt | grep -i "Unica " -A 1 | grep -vE "Unic" | tr -d '(0123456789)')

	echo -e "${grayColour}"
	echo "Año_Asignatura_Nota_Percentil_Suspensos" > table.txt

	while read asignatura ;do 
					
		
		notaArray+=($(cat notas.txt | grep -m 1  "${asignatura} " -A 1 | tail -n 1 | awk '{print$4}'))
		percentilArray+=($(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura} " -A 1 | tail -n 1 | awk '{print$3}'))
		aprobadosArray+=($(cat notas.txt | grep -i "suspendidos" -A 100 | grep "${asignatura} " -A 1 | tail -n 1 |awk '{print$6}'))
		suspensosArray+=($(cat notas.txt | grep -i "suspendidos" -A 100 | grep "${asignatura} " -A 1 | tail -n 1 |awk '{print$7}'))
	done < asignaturas.txt
		
		sortedSuspensos=($(printf '%s\n' ${suspensosArray[@]} | sort -n)) 
		
		IFS=$'\n' sortedNota=($(sort <<<"${notaArray[*]}"));
		IFS=$'\n' sortedPercentil=($(sort <<<"${percentilArray[*]}"));
		IFS=$'\n' sortedAprobados=($(sort <<<"${aprobadosArray[*]}"));
		unset IFS
			
		
		

		declare -i counter=0
		declare -i counterAsignatura=1
		
	while read asignatura ;do
	
		if [ "$option" == "nota" ];then	
			if [ "${sortedNota[counter]}" == ${sortedNota[counter-1]} ]; then
				let counterAsignatura+=1
			else
				let counterAsignatura=1
			fi
			miAsignatura=$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep -vE "\-|Unica" | tr -d '(0123456789)'| sed -n ${counterAsignatura}p)

			echo "$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep "^[[:digit:]]" | awk '{print$1}' | sed -n ${counterAsignatura}p)_$(cat notas.txt | grep -i "Unica " -B 1 | grep "${sortedNota[counter]}" -B 1 | grep -vE "\-|Unica" | tr -d '(0123456789)'| sed -n ${counterAsignatura}p)_${sortedNota[counter]}_$(cat notas.txt | grep -i "$miAsignatura" -A 1 | tail -n 1 | awk '{print$3}')_$(cat notas.txt | grep -i "$miAsignatura" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt
	
		elif [ "$option" == "año" ];then
			
			echo "$(cat notas.txt | grep -m 1  "${asignatura}" -A 1 | tail -n 1 | awk '{print$1}')_${asignatura}_$(cat notas.txt | grep -m 1  "${asignatura}" -A 1 | tail -n 1 | awk '{print$4}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$3}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt

		elif [ "$option" == "percentil" ];then

			if [ "${sortedPercentil[counter]}" == "${sortedPercentil[counter-1]}" ]; then
                        	let counterAsignatura+=1
                        else
                        	counterAsignatura=1
                        fi
			
			asignaturaPerc=$(cat notas.txt | grep "Asignatura .* ${sortedPercentil[counter]} " -B 1 | grep -vE "Asig|\-" | tr -d '(0123456789)' | sed -n ${counterAsignatura}p)
			echo "$(cat notas.txt | grep -m 1  "${asignaturaPerc}" -A 1 | tail -n 1 | awk '{print$1}')_${asignaturaPerc}_$(cat notas.txt | grep -m 1  "${asignaturaPerc}" -A 1 | tail -n 1 | awk '{print$4}')_${sortedPercentil[counter]}_$(cat notas.txt | grep   -i "Alumnos percentil" -A 100 | grep "${asignaturaPerc}" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt	

		elif [ "$option" == "suspendidos" ];then
			if [ "${sortedSuspensos[counter]}" == "${sortedSuspensos[counter-1]}" ]; then
                                  let counterAsignatura+=1
                          else
                                  counterAsignatura=1
                          fi
			asignaturaSusp=$(cat notas.txt | grep "^Asignatura .*  ${sortedSuspensos[counter]}" -B 1 | grep "% .* ${sortedSuspensos[counter]}" -B 1 | grep -vE "Asi|\-" | tr -d '(0123456789)' | sed -n ${counterAsignatura}p)


			echo "$(cat notas.txt | grep -m 1  "${asignaturaSusp}" -A 1 | tail -n 1 | awk '{print$1}')_${asignaturaSusp}_$(cat notas.txt | grep -m 1  "${asignaturaSusp}" -A 1 | tail -n 1 | awk '{print$4}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignaturaSusp}" -A 1 | tail -n 1 | awk '{print$3}')_${sortedSuspensos[counter]}" >> table.txt
		
		else

			echo "${year}_${asignatura}_$(cat notas.txt | grep -m 1  "${asignatura}"   -A 1 | tail -n 1 | awk '{print$4}')_$(cat notas.txt | grep -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$3}')_$(cat notas.txt | grep   -i "Alumnos percentil" -A 100 | grep "${asignatura}" -A 1 | tail -n 1 | awk '{print$7}')" >> table.txt # el problema esq la tabla se rellena n veces siendo n las asignaturas, habria que hacer otro while
		fi
	let counter+=1
	done < asignaturas.txt
		

	printTable '_' "$(cat table.txt)"
	echo -e "${endColour}"
	(rm notas.txt miasignatura.txt  asignaturas.txt  table.txt )  2>/dev/null
}

function asignaturaInfo(){
	echo -e "\n${grayColour}Analizando${endColour} ${yellowColour}${asignaturaElegida}${endColour}"

	nota=$(cat notas.txt | grep -m 1 -e "^${asignaturaElegida} " -A 1 | tail -n 1 | awk '{print$4}'| head -c 1)
	#suspensos=$(cat notas.txt | grep  -e "^${asignaturaElegida} " -A 2 | grep "^Asig" | awk '{print$7}')
	percentil=$(cat notas.txt | grep  -e "^${asignaturaElegida} " -A 2 | grep "^Asig" | awk '{print$3}')

	if [ ! "$nota" ];then
		echo -e "${redColour}\nEscoge una entre estas asignaturas:${endColour}\n"
		echo -e "\n${grayColour}$(cat notas.txt | grep "^Asig" -B 1 | grep -vE "Asi|\-" | tr -d '(0123456789)')"
		ctrl_c
	fi

	if [ "$nota" -eq "10" ];then
		echo -e "\n${grayColour}Dioss tienes un ${endColour}${yellowColour}$nota${endColour}${grayColour}. Esto es la perfección, mis mas sinceros respetos..."
		sleep 3
		echo -e "\nAunque..."
		sleep 3 
		echo -e "\nA lo mejor deberías dedicar mas tiempo a otras cosas..."
		sleep 3 
		echo -e "\nComo a aprender${redColour} BASH${endColour}"
		sleep 3 
		echo -e "\n\t${grayColour}\:)n"
		exit 1
	elif [ "$nota" -ge "9" ];then
		echo -e "\n${grayColour}Asombroso, sacaste un ${yellowColour}${nota}${endColour}${grayColour}. No mucha gente tiene esa nota..."
		sleep 3
		echo -e "\n${grayColour}Bueno, veamos el ${blueColour}percentil${endColour}${grayColour} para comparar"

		if [ "$percentil" -gt "50" ];then
			echo -e "\n${grayColour}Un percentil de ${percentil}, pues si que tienes buen percentil..."
			sleep 3
			echo -e "\nEnhorabuena"
			exit 1
		else	
			echo -e "\n${grayColour}Un percentil de ${percentil}..."
			sleep 3 
                  	echo -e "\nA lo mejor deberías dudar de lo que representa esa nota..."
			sleep 3                                                                                                                                        
                        echo -e "\n\t:)\n" 
		fi

	elif [ "$nota" -ge "7" ] && [ "$nota" -lt "9" ];then
		echo -e "\n${grayColour} Un ${endColour}${yellowColour}$nota${endColour}${grayColour}. Una muy buena nota."
        	sleep 3
                echo -e "\nEso significa que controlas de la materia..."
        	sleep 3 
                echo -e "\nVerdad?"
                sleep 3 
                echo -e "\nO es que todo el mundo ha sacado buena nota?"
                sleep 3 
                echo -e "\n${grayColour}Veamos el percentil..."
		if [ "$percentil" -gt "50" ];then  
                        echo -e "\n${grayColour}Un percentil de ${percentil}, pues si parece que controles..."
                        exit 1
                else    
                        echo -e "\n${grayColour}Un percentil de ${percentil}..."                                   
                        sleep 3                                                                                                                                        
                        echo -e "\nA lo mejor deberías dudar de lo que representa esa nota..."                         
                        sleep 3
			echo -e "\n\t:)\n"                                                 
                fi



	elif [ "$nota" -ge "5" ] && [ "$nota" -lt "7" ];then
		echo -e "\n${grayColour} Un ${endColour}${yellowColour}$nota${endColour}${grayColour} .No esta mal"
                sleep 3  
                echo -e "\nEso significa que controlas de la materia..."  
                sleep 3   
                echo -e "\nVerdad?"  
                sleep 3   
                echo -e "\nO es que todo el mundo ha sacado buena nota?"  
                sleep 3                                                                                              
                echo -e "\n${grayColour}Veamos el percentil..."  
                if [ "$percentil" -gt "50" ];then    
                        echo -e "\n${grayColour}Un percentil de ${percentil}, pues si parece que controles..."  
                        exit 1                                                                                                                                           
                else                                                                                                                                                     
                        echo -e "\n${grayColour}Un percentil de ${percentil}..."                                         
                        sleep 3                                                                                                                                          
                        echo -e "\nA lo mejor deberías dudar de lo que representa esa nota..."                           
                        sleep 3  
                        echo -e "\n\t:)\n"                                                   
                fi
	elif [ "$nota" -ge "4" ] && [ "$nota" -lt "5" ];then
		echo -e "\n${grayColour} Un${endColour}${yellowColour}$nota${endColour}${grayColour}Que mala pata!"
                  sleep 3    
                  echo -e "\nBueno, no te sientas mal, a lo mejor los demás también están como tú..."    
                  sleep 3  
                  echo -e "\nVerdad?"    
                  sleep 3  
                  echo -e "\nO eres el único?"    
                  sleep 3  
                  echo -e "\n${grayColour}Veamos el percentil...\n"    
                  if [ "$percentil" -gt "30" ];then  
                        echo -e "\n${grayColour}Un percentil de ${endColour}${yellowColour}${percentil}${endColour}${grayColour}, pues si que era difícil la asignatura"    
                        exit 1
                  else
                        echo -e "\n${grayColour}Un percentil de ${percentil}..."                                           
                        sleep 3
                        echo -e "\nPues tus compañeros tienen mejor nota..."                             
                	sleep 3    
			echo -e "\nA la próxima será"                                              
                        sleep 3
                        echo -e "\n\t\:\)\n"
		  fi
	else
		echo -e "\n${grayColour} Un ${endColour}${yellowColour}$nota${endColour}${grayColour}. Ale, a repetir curso que no tienes ni idea"
		sleep 3
        	echo -e "\n\t:)\n"
	fi
}


declare -i parameter_counter=0
while getopts "a:ng:c:o:hm:" arg; do
	case $arg in
		c)cookie_in=$OPTARG;;
		n)let parameter_counter+=2;;
		o)option=$OPTARG;;
		a)year=$OPTARG;;
		g)userPass=($OPTARG);let parameter_counter+=3;; #Escribe el nombre y contra entre ""
		m)asignaturaElegida=$OPTARG; let parameter_counter+=4;;
		h);;
	esac
done




if [ $parameter_counter -eq 2 ];then
	if [ "$option" ] && [ "$year" ];then
		echo -e "\n${grayColour}Escoge un criterio de ordenamiento con el parámetro ${purpleColour}-o${endColour}${grayColour}. O filtra por un año con el parametro${purpleColour} -a${endColour}${yellowColour}. PERO NO AMBOS!! ${endColour}\n"

	elif [ ! "$option" ] && [ ! "$year" ];then
		echo -e "\n${grayColour}Escoge un criterio de ordenamiento con el parámetro ${purpleColour}-o${endColour}${grayColour}. O filtra por un año con el parametro${purpleColour} -a${endColour} \n"
		ctrl_c
	else
	
	curl -s --cookie "TDp=$cookie_in" -d "p_curso=1" "https://intranet.upv.es/pls/soalu/sic_asi.notes_temaalu_asi" | html2text > notas.txt
	(cat notas.txt | grep -i "suspendidos") &>/dev/null
	
	if [ "$(echo $?)" -eq 0 ];then
		notasInfo
	else
		echo -e "${redColour}\nError ${endColour}${grayColour}Proporciona una cookie de sesión válida. Si no la tienes usa el parámetro -g "
	fi
	fi
elif [ $parameter_counter -eq 3 ];then
	getCookie
elif [ $parameter_counter -eq 4 ];then

	curl -s --cookie "TDp=$cookie_in" -d "p_curso=1" "https://intranet.upv.es/pls/soalu/sic_asi.notes_temaalu_asi" | html2text > notas.txt
        (cat notas.txt | grep -i "suspendidos") &>/dev/null
          
        if [ "$(echo $?)" -eq 0 ];then
        	asignaturaInfo ${asignaturaElegida} 
        else
        	echo -e "${redColour}\nError ${endColour}${grayColour}Proporciona una cookie de sesión válida. Si no la tienes usa el parámetro -g "
          fi
else
	helpPanel
fi
