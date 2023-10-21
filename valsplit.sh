#!/bin/bash
#@Author Muhammad Farooq

#allows for saving the line of code to either the correct or incorrect directories
save_to_file () {
	#instruction gets the split up array elements and strings them together with a space between each register etc.
	#e.g. from the array {'add', '$s0', '$s1', '$s2'} into 'add $s0 $s1 $s2'
	instruction="$(IFS=" "; echo "${array[*]}")"
	#stores the instruction/code line and a new line into $1 which is either the correctfile or incorrectfile directories
	#passed as an argument into this function
	echo -e "$instruction\r\n" >> $1
}

#checks the immediate values for lw, sw, and addi
check_immediates () {
	temp="("
	#checks first element of the array i.e. the mnemonic
	case ${array[0]} in
	#checks if it is addi
	addi)
		#if so, checks the fourth element of the array i.e. the immediate to see if it is within the immediate representable range (-32767 to 32767)
		if [ ${array[3]} -ge -32768 -a ${array[3]} -le 32767 ]; then
			#if so, calls the save_to_file function and passes the directory for the correct file ($correctfile) to save the line of code as correct
			echo "passed immediate check"
			save_to_file $correctfile
		else
			#otherwise, outputs an error
			echo "Error: The immediate is not within the representable range (-32767 to 32767)."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi;;
	#checks if mnemonic is either lw or sw
	lw | sw)
		#if so, checks the third element and retrieves the immediate by using $temp to stop before the '(' character appears
		#e.g. we have the offset/register '12($s0)', uses $temp which is '(' to stop at the first bracket and only retrieve '12'
		#now checks if this immediate is within the representable range (-32767 to 32767)
		if [  ${array[2]%$temp*} -ge -32768 -a ${array[2]%$temp*} -le 32767 ]; then
			#if so, calls the save_to_file function and passes the $correctfile directory to save the line of code as correct
			echo "passed immediate offset check"
			save_to_file $correctfile
		else
			#otherwise outputs an error message
			echo "Error: The immediate offset is not within the representable range (-32767 to 32767)."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi
	esac
}

#checks the syntax of the line of code
check_syntax () {
	count=0
	#gets first element of array
	case ${array[0]} in
	#checks if it is either add or sub
	add | sub)
		#for loop loops through the array but starts from index 1
		for i in "${array[@]:1}"
		do
			#checks the number of characters in $i (which is one of the registers)
			if [ ${#i} == 3 ]; then
				#if the length is 3 for the register i.e. $s0 equals 3 in length
				#then checks if $i starts with either $s or $t (i.e. the required registers)
				if [[ $i = '$s'* || $i = '$t'* ]]; then				
					#if so, it checks if the last character/digit of $i is greater than 0 or less than 7
					#which allows to determine if the register has a legal register number (any number from 0 to 7)
					if [ ${i: -1} -ge 0 -a ${i: -1} -le 7 ]; then
						#increments the variable count by 1
						((count++))
					fi
				fi
			fi
		done;;
	#checks if mnemonic/first array elements is addi
	addi)
		#if so, for loop starts at array index 1 and only carries out loops for the first two elements (from index 1 onwards)
		for i in "${array[@]:1:2}"
		do
			#checks if the register is 3 characters in length
			if [ ${#i} == 3 ]; then
				#if so, it checks if $i starts with either $s or $t (the valid registers)
				if [[ $i = '$s'* || $i = '$t'* ]]; then
					#if so, checks the last digit of $i is any number from 0 to 7 (legal register number)
					if [ ${i: -1} -ge 0 -a ${i: -1} -le 7 ]; then
						#if so, increments count by 1
						((count++))
					fi
				fi
			fi
		done;;
	#checks if first element of array is lw or sw
	lw | sw)
		#if so, checks if the second element of the array is 3 characters in length
		if [ ${#array[1]} == 3 ]; then
			#if so, checks if it starts with either $s or $t (the valid registers)
			if [[ ${array[1]} = '$s'* || ${array[1]} = '$t'* ]]; then
				#if so, checks if the last digit is any number from 0 to 7 (legal register number)
				if [ ${array[1]: -1} -ge 0 -a ${array[1]: -1} -le 7 ]; then
					#if so, increments count by 1
					((count++))
				fi
			fi
		fi
	
		#*checks the last 5 characters from the third element of the array (to retrieve the register from within the offset)
		#i.e. to retrieve $s0 from 12($s0)
		#then it checks if it matches the valid registers i.e. $s or $t
		if [[ ${array[2]: -5} = '($s'* || ${array[2]: -5} = '($t'* ]]; then
			#now it checks if the second last digit from the third element in the array is any number from 0 to 7
			if [ ${array[2]: -2:1} -ge 0 -a ${array[2]: -2:1} -le 7 ]; then
				#increments count by 1
				((count++))
			fi
		fi
	esac
	
	#checks the mnemonic
	case ${array[0]} in
	#if its add or sub
	add | sub)
		#checks if the register syntax has passed for all three registers
		if [ $count == 3 ]; then
			#if so, calls the save_to_file function and passes the $correctfile directory to save the line of code as correct
			echo "passed syntax check"
			save_to_file $correctfile
		else
			#otherwise outputs an error
            echo "Error: Incorrect syntax. Make sure registers start with either \$s or \$t followed by a legal register number (0-7)."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi;;
	#if mnemonic is lw, sw or addi
	lw | sw | addi)
		#checks if both the registers have passed syntax checks
		if [ $count == 2 ]; then
			#if so, calls the next check which is for immediates
			echo "passed syntax check"
			check_immediates
		else
		#otherwise outputs an error
			echo "Error: Incorrect syntax. Make sure registers start with either \$s or \$t followed by a legal register number (0-7)."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi
	esac
}

#checks the parameters
check_params () {
	#gets first element of array
	case ${array[0]} in
	#checks if it matches add, sub or addi
	add | sub | addi)
		#if so, checks if array length is equal to 4 which means that add, sub or addi will have 3 parameters
		if [ ${#array[@]} == 4 ]; then
			#if there is a correct number of arguments/parameters, it calls the next check for syntax
			echo "passed parameter check"
			check_syntax
		else
			#otherwise an error is outputted
			echo "Error: Incorrect number of arguments. Must have three arguments for add, sub, or addi."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi;;
	#checks if first element of array is either lw or sw
	lw | sw)
		#if so, it checks if the number of array elements is 3
		if [ ${#array[@]} == 3 ]; then
			#if so, this means that the line of code has 2 parameters and one mnemonic which is correct
			echo "passed parameter check"
			#calls check syntax to proceed
			check_syntax
		else
			#otherwise error message is outputted
			echo "Error: Incorrect number of arguments. Must have two arguments for lw or sw."
			#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
			save_to_file $incorrectfile
		fi
	esac
}

#checks the mnemonic
check_mnemonic () {
	#case checks first element of the array (which is the mnemonic)
	case ${array[0]} in
	#to see if its one of the following: add, sub, addi, lw or sw
	add | sub | addi | lw | sw)
		#if so, calls the next check which is for parameter checking
		echo "passed mnemonic check"
		check_params;;
	*)
		#otherwise outputs an error
		echo "Error: The instruction mnemonic must be one of add, sub, addi, lw or sw."
		#saves erroneous code to the incorrect file by calling save_to_file and passing the $incorrectfile
		save_to_file $incorrectfile
	esac
}

#allows for looping through each line of the input file
loop_lines () {
	#creates an array of lines from the input file, so each code line is stored as an element of the array lines
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'lines=($(cat $input))'

	#loops arround each line of the array called lines which holds each line of code from the input file
	for line in "${lines[@]}"; do
		#allows for splitting up the words (split up by a space) from $line into elements of an array
		#e.g. 'add $s0 $s1 $s2' into the array {'add', '$s0', '$s1', '$s2'}
		args=' ' read -r -a array <<< "$line"
		
		#calls the function check_mnemonic
		check_mnemonic
	done
}

#checks the number of arguments which have been passed into the script
check_scriptArgs () {
	if [ $# -ne 3 ]; then
		#if it is not equal to 3, then an error is outputted and the default files are chosen
		echo "Error: There must be three arguments, one input file and two output files. Default files will now be considered."
		input='input.txt'
		correctfile='correct.txt'
		incorrectfile='incorrect.txt'
	else
		#otherwise, if the correct number of arguments are passed, then it uses the users files for input, correctfile and incorrectfile
		input=$1
		correctfile=$2
		incorrectfile=$3
	fi
	
	#calls the function to loop through each line of the input file
	loop_lines
}

#calls the function to check the arguments passed to the script
check_scriptArgs