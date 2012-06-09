#!/bin/bash
#
# Moufoplot 
# Copyright (C) 2012 Vasileios Porpodas <v DOT porpodas AT ed.ac.uk>
#
# MoufoPlot is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# MoufoPlot is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with GCC; see the file COPYING3.  If not see
# <http://www.gnu.org/licenses/>.



# Input: FILE
# Output: A string with all the parts separated by space
# Example: get_all_parts_of_file jpeg_otp1_i1_d2
#          Returns: "jpeg opt1 i1 d2"
get_all_parts_of_file()
{
    local f=$1
    local parts=`echo $f |egrep -o "[[:alnum:]-]+"`
    RETVAL=${parts}
}


# Input: FILE PART_NUM
# Output: The value of the PART_NUM part of FILE
# Example: get_part_of_file jpeg_opt1_i1_d2 1 
#          Returns: opt1
get_part_of_file()
{
    local f=${1}
    local part=${2}
    get_all_parts_of_file ${f}
    local parts=${RETVAL}
    RETVAL=${parts[$part]}
}


# Input: FILE
# Output: The number of parts in FILE
# Example: count_parts jpeg_opt1_i1_d2
#         Returns: 4
count_parts()
{
    local f=${1}
    get_all_parts_of_file ${f}
    local p=${RETVAL}
    local parts_cnt=`echo $p|wc -w`
    RETVAL=${parts_cnt}
}


# Input: DIR PART_NUM
# Output: all the unique values in PART_NUM
# Example: get_all_values_in_part data/ 0 (where data/ contains files like jpeg_* and mpeg_*)
#          Returns "jpeg mpeg"
get_all_values_in_part()
{
    local DIR=$1
    local part=$2
    local files=`ls -1 $DIR`
    local all_values=()
    local f
    for f in $files; do
	get_part_of_file ${f} ${part}
	part_value=${RETVAL}
	local found=0
	# for val in ${all_values}; do
	#     if [ "$val" == "${part_value}" ];then
	# 	found=1
	#     fi
	# done
	if [ $found -eq 0 ]; then
	    all_values="${all_values} ${part_value}"
	fi
    done
    RETVAL=${all_values}
}


# Input: NEDDLE HAYSTACK
# Output: 1 if found, 0 if not found
# Example: found_in_array 1 "1 2 3"
#          Returns 1
found_in_array()
{
    local needle=$1
    local haystack=$2
    local found=0
    for hay in ${haystack}; do
	if [ "$needle" == "$hay" ]; then
	    found=1
	fi
    done
    echo $found
}

# Input: FIRST_NUM END_NUM NAME_PREFIX "SKIP_ARRAY"
# Output: the figure names
# Description: Generate names by concatenating the parts that correspond
#              to FIRST_NUM up to END_NUM excluding "SKIP_ARRAY".
gen_names()
{
    local i=$1
    local end_i=$2
    local name=$3
    local skip_i=$4
    
    while [ 0 ]; do
	local should_skip=`found_in_array $i "${skip_i}"`
	if [ $should_skip -eq 1 ];then
	    i=$((i + 1))
	else
	    break
	fi
    done
    local val
    for val in ${val_array[$i]}; do
	gen_names $((i+1)) ${end_i} "${name}_${val}" "${skip_i}"
    done
    if [ $i -eq ${end_i} ];then
	echo $name
    fi
}

# Input: DIR MATCHES
# Output: An array of all the files in DIR that match the MATCHES
# Example: get_match i2 jpeg d1 opt2
#          Returns jpeg_opt2_i2_d1
get_match ()
{
    local DIR=$1
    local matches=$2
    local exit_on_multiple_matches=$3
    local grep_cmd=""
    local out=""

    # echo "Matching... ${matches}"

    set_ifs ", "
    for match in $matches; do
	grep_cmd="${grep_cmd}|egrep \"_${match}_|^${match}_|_${match}\\$\""
    done
    reset_ifs

    grep_cmd="ls -1 ${DIR}${grep_cmd}"
    # echo "GREP_CMD: $grep_cmd"

    local filename=`eval ${grep_cmd}`
    local count_files=`echo $filename|wc -w`
    if [ ${count_files} -ne 1 ]&&[ "${exit_on_multiple_matches}" == "" ]; then
	if [ "${ignore_filter}" == "YES" ]&&[ ${count_files} -eq 0 ];then
	    echo -e "\nWARNING: Filter: ${matches} matches ${count_files} files in ${DIR} !!!"
	    RETVAL=""
	    return
	else
	    echo -e "\nERROR: Filter: ${matches} matches ${count_files} files in ${DIR} !!!"
    	    echo -e "FILES: $filename"
    	    exit 1
	fi
    fi
    # echo $filename
    out="${filename} ${out}"
    RETVAL=${out}
}


# Input: X_ARRAY MAX
# Output: An array of the part numbers that are not part of the X Axis.
# Example: get_not_x "0 1" 4
#          Returns "2 3"
get_not_x()
{
    local x_values=$1
    local parts_cnt=$2
    local i=0
    while [ $i -lt ${parts_cnt} ]; do
	local found=`found_in_array $i "${x_values}"`
	if [ $found -eq 0 ]; then
	    local not_x_values="${not_x_values} $i"
	fi
	i=$((i+1))
    done
    echo ${not_x_values}
}

# Input: FILE
# Output: The number contained in FILE
# Example: get_file_value jpeg_opt1_i2_d1
#          Returns 34896523
get_file_value()
{
    local file=$1
    local data=`cat ${file}`

    # echo "Reading value from ${file}... ${data}"
    if [ "$data" == "" ]; then
	if [ "${ignore_filter}" == "YES" ];then
	    echo "WARNING: ignoring empty ${file}."
	    RETVAL=0
	    return
	else
	    echo "ERROR: file ${file} is empty!!!"
	    exit 1
	fi
    fi
    is_number "${data}"
    local isnum=${RETVAL}
    if [ "${isnum}" == "no" ];then
	is_exponential_notation "${data}"
	local isexp=${RETVAL}
	if [ "${isexp}" == "no" ];then
	    echo "ERROR: file: ${file}: ${data} is not a number OR an exponential."
	    exit 1
	else
	    # number is in exponential notation. we have to convert it to float
	    local first=`echo ${data} | egrep -o "[0-9]+(\.[0-9]+|)" | head -n 1`
	    local last=`echo ${data} | egrep -o "([Ee]\+[0-9]+|)" |egrep -o "[0-9]+"`
	    # echo "data: ${data}, first: ${first}, last: ${last}"
	    local float_val=`echo "${first} * 10 ^ ${last}" |bc -l`
	    data=${float_val}
	fi
    fi
    # echo ${data}
    RETVAL=${data}
}

# Input: DATA_FILE_ARRAY OUT_DIR
# Output: NORMALIZED_DATA_FILE_ARRAY
normalize()
{
    local RES_DIR=$1
    local OUT_DIR=$2

    if [ ! -d ${OUT_DIR} ]; then
	mkdir ${OUT_DIR}
    fi

    NOED_i1_d1=`cat ${RES_DIR}/*_NOED_i1_d1`

    local results=`ls -1 ${RES_DIR}`

    for result in ${results}; do
	result_path="${RES_DIR}/${result}"
	result_num=`cat ${result_path}`
	normalized_result_num=`echo "${result_num}/${NOED_i1_d1}" | bc -l`
	normalized_result_path="${OUT_DIR}/${result}"
	echo ${normalized_result_num} > ${normalized_result_path}
    done
    echo "Done!"
}

is_exponential_notation()
{
    value=${1}
    grepped_val=`echo ${1} | egrep -o "[0-9]+(\.[0-9]+|)([Ee]\+[0-9]+|)" | head -n 1`
    if [ "${value}" == "${grepped_val}" ]; then
	RETVAL="yes"
    else
	RETVAL="no"
    fi
}

is_number()
{
    value=${1}
    grepped_val=`echo ${1} | egrep -o "(-|)([[:digit:]]+\.*[[:digit:]]*)" | head -n 1`
    if [ "${value}" == "${grepped_val}" ]; then
	RETVAL="yes"
    else
	RETVAL="no"
    fi
}


is_integer()
{
    value=${1}
    grepped_val=`echo ${1} | egrep -o "(-|)([[:digit:]])+"`
    if [ "${value}" == "${grepped_val}" ]; then
	RETVAL="yes"
    else
	RETVAL="no"
    fi
}

h
gp_bar_options()
{
    local rowstacked=${1}

# the yrange for each row starting from row 0 
    local Y_RANGE_ENABLED=1
    local yrange_row=(0: 0: 0: 0: 0: 0: 0:) # Lowest first
    local size_x=0.4
    local size_y=0.5
    # local KEYSTUFF="inside top"
    local KEYSTUFF="tmargin"
    local LW=4
    local POINTSIZE=2
    local LEG_X=0
    local LEG_Y=0

    local FONTSIZE="38"

    local KEYFONTSIZE="34"
    local KEYFONTSPACING="3.7"
    local TICSFONTSIZE="30"

    local XLABELOFFSET="0,-2.0"
    local YLABELOFFSET="-3.0,0"
    local LABELFONTSIZE=$FONTSIZE
    local LABELFONTSIZE="28"


    local argfname=`echo ${data_file}|sed s'/\///g'`
    # local gpfname="${argfname}.gp"
    # echo "Generating ${gpfname} data_file:${data_file}, boxwidth=$boxwidth, yrange_enabled=${Y_RANGE_ENABLED}, yrange=${yrange}, lw=$LW, x:$x_title, y:$y_title, legend=(${LEG_X},${LEG_Y}), legend:$KEYSTUFF."
    local FILE="${gpfname}"

    if [ "${size_param}" != "" ];then
	local size="${size_param_x},${size_param_y}"
    else
	local size="$size_x,$size_y"
    fi

    echo "set term postscript eps enhanced color" > $FILE 

    echo "set output \"${epsfile}\"" >>$FILE

    echo "unset ylabel" >> $FILE
    echo "set grid y" >>$FILE
    # echo "set grid x" >>$FILE
    echo "${ytics_command}" >> $FILE

    echo "set xtics rotate by ${x_tics_rotate} offset character 0,0 nomirror" >> $FILE
    if [ "${x_format}" != "" ];then
	echo "set format x \"${x_format}\"" >> $FILE
    fi
    if [ "${y_format}" != "" ];then
	echo "set format y \"${y_format}\"" >> $FILE
    fi

# echo "set ytics 1" >>$FILE
    echo " " >> $FILE
    # echo "set key $KEYSTUFF" >> $FILE
    echo "${key_command}" >> $FILE
    echo " " >> $FILE
    # echo "set tics font \"Times,$TICSFONTSIZE\""  >> $FILE
    # echo "set key font \"Times,$KEYFONTSIZE\" spacing $KEYFONTSPACING">> $FILE

    # echo "set main_title \"{${fname}}\" font \"Times,$FONTSIZE\" " >> $FILE
    # local main_title=${data_file##*/}
    if [ "${main_title}XX" != "XX" ];then
	echo "set title \"${main_title}\" " >> $FILE
    fi

    echo "set size $size" >> $FILE

    # if [ ${Y_RANGE_ENABLED} -eq 1 ]; then
    # 	echo "set yrange[${yrange_row[$row]}] ">> $FILE
    # fi
    if [ "${y_range}" != "" ]; then
	echo "set yrange[${y_range_min}:${y_range_max}]">> $FILE
    fi



    # echo "set xrange[0:]" >> $FILE

    # Bargraph specific
    if [ "${bar_width}" != "" ];then
	echo "set boxwidth ${bar_width} relative" >> $FILE
    fi
    echo "set style data histograms" >> $FILE
    # offset is relative to xlabel


    if [ "${rowstacked}" == "" ];then
	if [ "${cluster_gap}" != "" ]; then
    	    echo "set style histogram cluster gap ${cluster_gap} title offset 0,0.2" >> $FILE
	else
    	    echo "set style histogram cluster gap 1 title offset 0,0.2" >> $FILE
	fi
    else
    	echo "set style histogram ${rowstacked} title offset 0,0.2" >> $FILE
    fi

    echo "set style fill solid 1.0 border lt \"black\"" >> $FILE
    echo "set grid ytics ls 10 lt rgb \"black\"" >> $FILE


    # x,y titles
    # local x_vals_array=(${x_vals})
    # local y_vals_array=(${y_vals})
    # local x_title=`echo ${x_vals_array[0]} |egrep -o "[[:alpha:]-]+"`
    # local y_title=`echo ${y_vals_array[0]} |egrep -o "[[:alpha:]-]+"`
    # echo "set ylabel \"${y_title}\""  >> $FILE
    # echo "set xlabel \"${x_title}\""  >> $FILE
    echo "set xlabel \" ${x_title}\" offset 0,-0.4"  >> $FILE
    if [ "${ytitle}" != "" ]; then
	echo "set ylabel \"${ytitle}\""  >> $FILE
    fi


    # PLOT
    local plot_cmd="plot "
    local x_set_array=(${x_set})
    local x
    local cmn=2
    set_ifs "${IFS_CHAR}"
    local xi=0
    local z

    if [ "${z_vals}" == "" ];then
	for x in ${x_vals}; do
	# skip masked
	    if [ "${x_mask}" != "" ]&&[ "${x_mask_array[${xi}]}" == "0" ];then
		xi=$((${xi} + 1))
		continue
	    fi

	    local color=${color_array[$cmn]}
	    plot_cmd="${plot_cmd} \"${data_file}\" using ${cmn}:xtic(1) with histograms title columnheader(${cmn}) lt 1 lw ${bar_line_width} lc rgb \"${color}\","
	    cmn=$((cmn+1))
	    xi=$((${xi} + 1))
	done
    else
	local zi=0
	for z in ${z_vals}; do
	    local cmn=2

	    if [ "${ztags_array[${zi}]}" != "" ];then
		local ztag=${ztags_array[${zi}]}
		ztag=`echo ${ztag}|sed 's/ /_/g'` # Remove spaces
	    else
		local ztag=${z}
		ztag=`echo ${ztag}|sed 's/ /_/g'` # Remove spaces
	    fi

	    plot_cmd="${plot_cmd} newhistogram \"${ztag}\", "
	    for x in ${x_vals}; do
		# skip masked
		if [ "${x_mask}" != "" ]&&[ "${x_mask_array[${xi}]}" == "0" ];then
		    xi=$((${xi} + 1))
		    continue
		fi

		local color=${color_array[$cmn]}
		if [ ${zi} -eq 0 ];then
		    local title_stuff="title columnheader(${cmn})"
		else
		    local title_stuff="notitle"
		fi
		plot_cmd="${plot_cmd} \"${data_file}\" index ${zi} using ${cmn}:xtic(1) with histograms ${title_stuff} lt 1 lw ${bar_line_width} lc rgb \"${color}\","

		cmn=$((cmn+1))
		xi=$((${xi} + 1))
	    done
	    zi=$((${zi} + 1))
	done
    fi
    reset_ifs
    echo "${plot_cmd%?}" >> $FILE
    gnuplot ${gpfname}

}

gp_line_options()
{
    local DATA_FILE=$1
    local x_vals=$2
    local y_vals=$3
    local title=$4
    local xtitle=$5
    local ytitle=$6

# the yrange for each row starting from row 0 
    local Y_RANGE_ENABLED=1
    local yrange_row=(0: 0: 0: 0: 0: 0: 0:) # Lowest first
    local size_x=0.4
    local size_y=0.5
    # local KEYSTUFF="inside top"
    local KEYSTUFF="tmargin"
    local LW=4
    local POINTSIZE=2
    local LEG_X=0
    local LEG_Y=0

    local FONTSIZE="38"

    local KEYFONTSIZE="34"
    local KEYFONTSPACING="3.7"
    local TICSFONTSIZE="30"

    local XLABELOFFSET="0,-2.0"
    local YLABELOFFSET="-3.0,0"
    local LABELFONTSIZE=$FONTSIZE
    local LABELFONTSIZE="28"


    local argfname=`echo ${DATA_FILE}|sed s'/\///g'`
    # local gpfname="${argfname}.gp"
    # echo "Generating ${gpfname} DATA_FILE:${DATA_FILE}, boxwidth=$boxwidth, yrange_enabled=${Y_RANGE_ENABLED}, yrange=${yrange}, lw=$LW, x:$xtitle, y:$ytitle, legend=(${LEG_X},${LEG_Y}), legend:$KEYSTUFF."
    local FILE="${gpfname}"

    if [ "${size_param}" != "" ];then
	local size="${size_param_x},${size_param_y}"
    else
	local size="$size_x,$size_y"
    fi

    echo "set term postscript eps enhanced color" > $FILE 

    echo "set output \"${epsfile}\"" >>$FILE

    echo "unset ylabel" >> $FILE
    echo "set grid y" >>$FILE
    # echo "set grid x" >>$FILE
    echo "${ytics_command}" >> $FILE
    echo "set xtics rotate by ${x_tics_rotate} offset character 0,0" >> $FILE
    if [ "${x_format}" != "" ];then
	echo "set format x \"${x_format}\"" >> $FILE
    fi
    if [ "${y_format}" != "" ];then
	echo "set format y \"${y_format}\"" >> $FILE
    fi

# echo "set ytics 1" >>$FILE
    echo " " >> $FILE
    # echo "set key $KEYSTUFF" >> $FILE
    echo "${key_command}" >> $FILE
    echo " " >> $FILE
    # echo "set tics font \"Times,$TICSFONTSIZE\""  >> $FILE
    # echo "set key font \"Times,$KEYFONTSIZE\" spacing $KEYFONTSPACING">> $FILE

    # echo "set title \"{${fname}}\" font \"Times,$FONTSIZE\" " >> $FILE
    # local title=${DATA_FILE##*/}
    if [ "${title}XX" != "XX" ];then
	echo "set title \"${title}\" " >> $FILE
    fi

    echo "set size $size" >> $FILE

    # if [ ${Y_RANGE_ENABLED} -eq 1 ]; then
    # 	echo "set yrange[${yrange_row[$row]}] ">> $FILE
    # fi
    if [ "${y_range}" != "" ]; then
	echo "set yrange[${y_range_min}:${y_range_max}]">> $FILE
    fi

    echo "set xrange[0:]" >> $FILE


 
    # x,y titles
    # local x_vals_array=(${x_vals})
    # local y_vals_array=(${y_vals})
    # local xtitle=`echo ${x_vals_array[0]} |egrep -o "[[:alpha:]-]+"`
    # local ytitle=`echo ${y_vals_array[0]} |egrep -o "[[:alpha:]-]+"`
    if [ "${xtitle}" != "" ]; then
	echo "set xlabel \"${xtitle}\""  >> $FILE
    fi
    if [ "${ytitle}" == "" ]; then
	echo "set ylabel \"${ytitle}\""  >> $FILE
    fi



    # PLOT
    local plot_cmd="plot "
    local x_set_array=(${x_set})
    local x
    local cmn=2
    local xi=0
    set_ifs "${IFS_CHAR}"
    for x in ${x_vals}; do
	# skip masked
	if [ "${x_mask}" != "" ]&&[ "${x_mask_array[${xi}]}" == "0" ];then
	    xi=$((${xi} + 1))
	    continue
	fi

	local color=${color_array[$cmn]}
	plot_cmd="${plot_cmd} \"${DATA_FILE}\" using ${cmn}:xtic(1) with linespoints title columnheader(${cmn}) lw $LW lc rgb \"${color}\","
	cmn=$((cmn+1))
	xi=$((${xi} + 1))
    done
    reset_ifs
    echo "${plot_cmd%?}" >> $FILE
    gnuplot ${gpfname}
}


create_tics()
{
    local xORy="${1}"
    # TICS: set xtics ("aaa" 0, "bbb" 1, ...)

    set_ifs ","
    if [ "${xORy}" == "x" ];then
	local x
	local xtics_cmd="set xtics ("
	local skipped=0
	local xi=0
	for x in ${x_vals}; do
	    # skip X masked data
	    if [ "${x_mask}" != "" ]&&[ "${x_mask_array[${xi}]}" == "0" ];then
		xi=$((${xi} + 1))
		skipped=$((${skipped} + 1))
		continue
	    fi

	    if [ "${x_tags}" != "" ]; then
		local tag="${xtags_array[${xi}]}"
	    else
		local tag=${x}
	    fi
	    xtics_cmd="${xtics_cmd}\"${tag}\" $((${xi}-${skipped})),"
	    xi=$((${xi} + 1))
	done
	RETVAL="${xtics_cmd%?})"
    elif [ "${xORy}" == "y" ];then
	local y
	local ytics_cmd="set ytics ("
	local yi=0
	local skipped=0
	for y in ${y_vals}; do
            # skip Y masked data
	    if [ "${y_mask}" != "" ]&&[ "${y_mask_array[${yi}]}" == "0" ];then
		yi=$((${yi} + 1))
		skipped=$((${skipped} + 1))
		continue
	    fi

	    if [ "${ytags_array[${yi}]}" != "" ]; then
		local tag="${ytags_array[${yi}]}"
	    else
		local tag=${y}
	    fi
	    ytics_cmd="${ytics_cmd}\"${tag}\" $((${yi} - ${skipped})),"
	    yi=$((${yi} + 1))
	done
	RETVAL="${ytics_cmd%?})"
     fi
    reset_ifs 
}

gp_heatmap_options()
{
    local DATA_FILE=$1

    local rows=1
    local columns=1
    local x_vals=$2
    local y_vals=$3
    local title=$4
    local xtitle=$5
    local ytitle=$6

# the yrange for each row starting from row 0 
    local Y_RANGE_ENABLED=1
    local yrange_row=(0: 0: 0: 0: 0: 0: 0:) # Lowest first
    local size_x=0.4
    local size_y=0.5
#bottom_margin=`echo "${size_y}/2.0" |bc -l`
    local bottom_margin=0.01
    # local KEYSTUFF="inside top"
    local KEYSTUFF="tmargin"
    local LW=7
    local POINTSIZE=3
    local LEG_X=0
    local LEG_Y=0
    local boxwidth=0.2

    # local yrange="0.5:"

    local FONTSIZE="38"

    local KEYFONTSIZE="34"
    local KEYFONTSPACING="3.7"
    local TICSFONTSIZE="30"

    local XLABELOFFSET="0,-2.0"
    local YLABELOFFSET="-3.0,0"
    local LABELFONTSIZE=$FONTSIZE
    local LABELFONTSIZE="28"


    local argfname=`echo ${DATA_FILE}|sed s'/\///g'`
    # local gpfname="${argfname}.gp"
    # echo "Generating ${gpfname} DATA_FILE:${DATA_FILE}, $gpcol, boxwidth=$boxwidth, yrange_enabled=${Y_RANGE_ENABLED}, yrange=${yrange}, lw=$LW, x:$xtitle, y:$ytitle, legend=(${LEG_X},${LEG_Y}), legend:$KEYSTUFF."
    local FILE="${gpfname}"
    if [ "${size_param}" != "" ];then
	local size="${size_param_x},${size_param_y}"
    else
	local size="$size_x,$size_y"
    fi

    echo "set term postscript eps enhanced color" > $FILE 
    echo "set output \"${epsfile}\"" >>$FILE
    echo "set boxwidth $boxwidth" >> $FILE
    echo "unset ylabel" >> $FILE
    # echo "set xtics 1" >>$FILE
    echo "set xtics rotate by ${x_tics_rotate} offset character 0,0 " >> $FILE

    if [ "${x_format}" != "" ];then
	echo "set format x \"${x_format}\"" >> $FILE
    fi
    if [ "${y_format}" != "" ];then
	echo "set format y \"${y_format}\"" >> $FILE
    fi

# echo "set ytics 1" >>$FILE
    echo " " >> $FILE
    # echo "set key $KEYSTUFF" >> $FILE
    echo " " >> $FILE
    # echo "set size  `echo \"$columns * $size_x\"|bc`,`echo \"$rows * $size_y + $bottom_margin\"|bc`" >> $FILE
    # echo "set multiplot" >> $FILE
    # echo "set tics font \"Times,$TICSFONTSIZE\""  >> $FILE
    # echo "set key font \"Times,$KEYFONTSIZE\" spacing $KEYFONTSPACING">> $FILE

    # Heatmap excluseive options
    echo "set palette rgbformula 7,7,7" >> $FILE
    echo "set palette rgbformula 30,31,32" >> $FILE
    echo "set cblabel \"\""  >> $FILE
    echo "unset cbtics" >> $FILE
    echo "unset key" >> $FILE # Otherwise the filename is displayed
    # echo "set xrange [-0.5: ]" >> $FILE
    # echo "set yrange [-0.5: ]" >> $FILE


    # local title=${DATA_FILE##*/}
    # local title="TITLE"
    # echo "set title \"{${title}}\" font \"Times,$FONTSIZE\" " >> $FILE
    if [ "${title}XX" != "XX" ];then
	echo "set title \"${title}\" " >> $FILE
    fi
    echo "set size $size" >> $FILE
	# echo "set origin `echo \"$col * $size_x\"|bc`,`echo \"$row * $size_y + $bottom_margin\"|bc`" >> $FILE
    # echo "set pointsize 3" >> $FILE
    # echo "set style line 6 lt 7">> $FILE

	# echo "set boxwidth 1 relative" >> $FILE
	# echo "set style data histograms" >> $FILE

	# echo "set style histogram cluster gap 1" >> $FILE
	# echo "set style fill solid 1.0 border lt \"black\"" >> $FILE
	# echo "set grid ytics ls 10 lt rgb \"black\"" >> $FILE



    # x,y titles
    # local x_vals_array=(${x_vals})
    # local y_vals_array=(${y_vals})
    # local xtitle=`echo ${x_vals_array[0]} |egrep -o "[[:alpha:]-]+"`
    # local ytitle=`echo ${y_vals_array[0]} |egrep -o "[[:alpha:]-]+"`

    # echo "set ylabel \"${ytitle}\" font \"Times,$LABELFONTSIZE\" offset $YLABELOFFSET" >> $FILE
    # echo "set xlabel \"${xtitle}\" font \"Times,$LABELFONTSIZE\" offset $XLABELOFFSET" >>$FILE
    # echo "set ylabel \"${ytitle}\""  >> $FILE
    # echo "set xlabel \"${xtitle}\""  >> $FILE

    if [ "${xtitle}" != "" ]; then
	echo "set xlabel \"${xtitle}\""  >> $FILE
    fi
    if [ "${ytitle}" != "" ]; then
	echo "set ylabel \"${ytitle}\""  >> $FILE
    fi

    create_tics "x"
    local xtics_cmd="${RETVAL}"
    echo "${xtics_cmd}" >> $FILE

    create_tics "y"
    local ytics_cmd="${RETVAL}"
    echo "${ytics_cmd}" >> $FILE

 
	# PLOT
    local plot_cmd="plot "
    plot_cmd="${plot_cmd} \"${DATA_FILE}\" matrix with image"
    echo "${plot_cmd}" >> $FILE

    gnuplot ${gpfname}
}

# set IFS to the given value and save the previous one
set_ifs()
{
    local CURRENT_IFS="${1}"
    IFS="${CURRENT_IFS}"
    IFS_STACK[${IFS_CNT}]="${CURRENT_IFS}"
    IFS_CNT=$((IFS_CNT + 1))
    # echo "set_ifs: ->${CURRENT_IFS}<-, stack_cnt:${IFS_CNT}"
}

# reset IFS to the last one
reset_ifs()
{
    local IFS_CNT_PREV=$((IFS_CNT - 1))
    if [ ${IFS_CNT_PREV} -ge 0 ];then
	local IFS_CURRENT=${IFS_STACK[${IFS_CNT_PREV}]}
	IFS=${IFS_CURRENT}
	IFS_CNT=${IFS_CNT_PREV}
	# echo "reset_ifs: ->${IFS_CURRENT}<-, stack_cnt:${IFS_CNT}"
    else
	echo "Too many reset_ifs !!!"
	exit 1
    fi
}

find_min_max()
{
    local file_val=${1}
    if [ "${max_value}" == "" ];then
	max_value=${file_val}
    else
	local isgt=`greater_than ${file_val} ${max_value}`
	if [ "${isgt}" == "1" ];then
	    max_value=${file_val}
	fi
    fi
    if [ "${min_value}" == "" ];then
	min_value=${file_val}
    else
	local islt=`less_than ${file_val} ${max_value}`
	if [ "${islt}" == "1" ];then
	    min_value=${file_val}
	fi
    fi
}

pretty_tics()
{
    if [ "${y_tics}" != "" ];then
	local y_dist=`echo "(${max_value} - ${min_value}) / ${y_tics}"|bc -l`
	local is_y_dist_gt3=`greater_than ${y_dist} 3`
	if [ "${is_y_dist_gt3}" == "1" ];then
	    local y_dist=${y_dist/.*}
	fi
	ytics_command="set ytics ${y_dist}"
	echo "YTICS: ${ytics_command}"
    fi
}

yrange_tics()
{
    if [ "${y_range_step}" != "" ];then
	ytics_command="set ytics ${y_range_step}"
    fi
}

# Input: "X_VALUES" "Y_VLUES" FILENAME
# Output: creates FILENAME and puts in it all the data.
# Description: Create the data file for a figure. 
create_data_file()
{
    local x_array=${x_vals}
    local y_array=${y_vals}
    local out_file=$1
    local others=$2
    local z_array=${z_vals}
    local x
    local y
    local z
    local fig_options=`get_all_parts_of_file "${fig_file}"`

    printf "Creating data file ${data_file} ..."
    set_ifs "${IFS_CHAR}" # Let ',' be the separator character


    # avg
    local max_x=0
    for x in ${x_array}; do
	max_x=$((${max_x} + 1))
    done
    local max_y=0
    for y in ${y_array}; do
	max_y=$((${max_y} + 1))
    done
    if [ "${x_avg}" != "" ];then
	x_array="${x_array},avg"
	x_vals=${x_array}
    fi
    local ysum
    if [ "${y_avg}" != "" ];then
    	y_array="${y_array},avg"
	y_vals=${y_array}
	local yi=0
	while [ ${yi} -lt ${max_y} ];do
	    ysum[${yi}]="0"
	    yi=$((${yi} + 1))
	done
    fi



    local data="NULL"

    
    local xi=0
    for x in ${x_array}; do
	if [ "${x_tags}" != "" ];then
	    local xtag=${xtags_array[${xi}]}
	else
	    local xtag=${x}
	fi

        # skip masked data
	if [ "${x_mask}" != "" ]&&[ "${x_mask_array[${xi}]}" == "0" ];then
	    xi=$((${xi} + 1))
	    continue
	fi

	data="${data} ${xtag}"
	xi=$((${xi} + 1))
    done
    data="${data}\n"

    if [ "${z_array}" == "" ];then
	z_array="NO-ZAXIS"
	local no_z=1
    fi

    local zi=0
    for z in ${z_array};do
	if [ "${no_z}" == "1" ];then
	    z=""
	fi

	data="${data}# ${z}\n"
	local yi=0    
	local normalize_value=1.0
	for y in ${y_array}; do
	    if [ "${ytags_array[${yi}]}" != "" ];then
		local ytag=${ytags_array[${yi}]}
		ytag=`echo ${ytag}|sed 's/ /_/g'` # Remove spaces
	    else
		local ytag=${y}
		ytag=`echo ${ytag}|sed 's/ /_/g'` # Remove spaces
	    fi

        # Normalization on the Y axis
	    if [ "${y_norm_array[${yi}]}" != "" ];then
		normalize_value=`echo ${y_norm_array[${yi}]}*1.0|bc -l`
	    fi

	# skip Y tag (masked Y)
	    if [ "${y_mask_array[${yi}]}" != "0" ];then
		data="${data}${ytag}"
	    fi

	    local sumx="0"
	    local xi=0
	    for x in ${x_array}; do

		if [ ${xi} -lt ${max_x} ]&&[ ${yi} -lt ${max_y} ];then # x/y avg
		    local opts="${x} ${y} ${z} ${others}"
		    get_match "${DIR}" "$opts"
		    local file=${RETVAL}
		    if [ "${ignore_filter}" == "YES" ]&&[ "${RETVAL}" == "" ];then
			RETVAL=0
		    else
			get_file_value "${DIR}/${file}"
		    fi
		    local file_val=${RETVAL}

	        # Normalization on the X axis
		    if [ "${x_norm_array[${xi}]}" != "" ];then
			normalize_value=`echo "${x_norm_array[${xi}]} * 1.0"|bc -l`
		    fi
		    if [ "${ignore_filter}" == "YES" ]&&[ "${file_val}" == "0" ]||[ "${ignore_filter}" == "YES" ]&&[ "${normalize_value}" == "0" ];then
			file_val=0
		    else
			file_val=`echo "${file_val} / ${normalize_value}"|bc -l`
		    fi

		    if [ "${percent}" != "" ];then
			file_val=`echo "${file_val} * 100" |bc -l`
		    fi
		else
		    if [ ${yi} -eq ${max_y} ];then
			file_val=`echo "(${ysum[${xi}]}) / ${avg_max_y}" | bc -l`
		    fi
		    if [ ${xi} -eq ${max_x} ];then
			file_val=`echo "(${sumx})/${avg_max_x}" | bc -l`
		    fi
		fi


	    # Find minimum, maximum value (to use it in pretty ytics)
		find_min_max ${file_val}

	    # skip X,Y masked data
		if [ "${x_mask_array[${xi}]}" != "0" ]&&[ "${y_mask_array[${yi}]}" != "0" ];then
		    data="${data} ${file_val}"
		fi

		in_array ${xi} "${x_avg_array[@]}"
		if [ $? -eq 0 ];then
		    sumx="${sumx} + ${file_val}"
		fi

		in_array ${yi} "${y_avg_array[@]}"
		if [ $? -eq 0 ];then
		    ysum[${xi}]="${ysum[${xi}]} + ${file_val}"
		fi
		xi=$((${xi} + 1))
	    done

	# skip Y newline (masked Y)
	    if [ "${y_mask_array[${yi}]}" != "0" ];then
		data="${data}\n"
	    fi
	    yi=$((${yi} + 1))
	done
	if [ "${z_mask_array[${zi}]}" != "0" ];then
	    data="${data}\n\n"
	fi
	zi=$((${zi} + 1 ))
    done
    reset_ifs
    printf " Done.\n"
    # Dump data
    echo -e $data |tee ${out_file}
    
    pretty_tics
    yrange_tics
}


in_array()
{
    local hay needle=${1}
    shift
    for hay; do
        [[ ${hay} == ${needle} ]] && return 0
    done
    return 1
}

# Input: "X_VALUES" "Y_VLUES" FILENAME
# Output: creates FILENAME and puts in it all the data.
# Description: Create the data file for a heatmap. 
create_heatmap_data_file()
{
    local x_array=${x_vals}
    local y_array=${y_vals}
    local out_file=$1
    local others=$2
    local x
    local y
    local fig_options=`get_all_parts_of_file "${fig_file}"`

    # avg
    local max_x=0
    for x in ${x_array}; do
	max_x=$((${max_x} + 1))
    done
    local max_y=0
    for y in ${y_array}; do
	max_y=$((${max_y} + 1))
    done
    if [ "${x_avg}" != "" ];then
	x_array="${x_array},avg"
	x_vals=${x_array}
    fi
    local sumy
    if [ "${y_avg}" != "" ];then
    	y_array="${y_array},avg"
	y_vals=${y_array}
	local yi=0
	while [ ${yi} -lt ${max_y} ];do
	    sumy[${yi}]="0"
	    yi=$((${yi} + 1))
	done
    fi



    local data=""
    set_ifs "${IFS_CHAR}" # Let ',' be the separator character
    local yi=0
    for y in ${y_array}; do
	local sumx="0"
	local xi=0
	for x in ${x_array}; do

	    if [ ${xi} -lt ${max_x} ]&&[ ${yi} -lt ${max_y} ];then # x/y avg
		local opts="${x} ${y} ${others}"
		get_match "$DIR" "$opts"
		local file=${RETVAL}
		get_file_value "${DIR}/${file}"
		local file_val=${RETVAL}
		if [ "${percent}" != "" ];then
		    file_val=`echo "${file_val} * 100" |bc -l`
		fi
	    else
		if [ ${yi} -eq ${max_y} ];then
		    file_val=`echo "(${sumy[${xi}]}) / ${avg_max_y}" | bc -l`
		fi
		if [ ${xi} -eq ${max_x} ];then
		    file_val=`echo "(${sumx})/${avg_max_x}" | bc -l`
		fi
	    fi
	    if [ "${x_mask_array[${xi}]}" != "0" ]&&[ "${y_mask_array[${yi}]}" != "0" ];then
		data="${data}${file_val} "
	    fi

	    in_array ${xi} "${x_avg_array[@]}"
	    if [ $? -eq 0 ];then
		sumx="${sumx} + ${file_val}"
	    fi

	    in_array ${yi} "${y_avg_array[@]}"
	    if [ $? -eq 0 ];then
		sumy[${xi}]="${sumy[${xi}]} + ${file_val}"
	    fi
	    xi=$((${xi} + 1))
	done

	if [ "${y_mask_array[${yi}]}" != "0" ];then
	    data="${data}\n"
	fi
	yi=$((${yi} + 1))
    done
    reset_ifs
    echo "${out_file}"
    echo "- - - - - - - - - - - -"
    echo -e $data |tee ${out_file}
}


check_if_arguments_exist()
{
    set_ifs "${IFS_CHAR}" # Let ',' be the separator character
    local vals1=$1
    local vals2=$2
    local vals3=$3
    local dir=$4
    local val1
    local val2
    local val3
    for val1 in ${vals1}; do
	for val2 in ${vals2}; do
	    for val3 in ${vals3}; do
		get_match "${DIR}" "${val1} ${val2} ${val3}" "NO"
		# local matches=${RETVAL}
		if [ $? -ne 0 ]; then
		    echo "ERROR: Filters: ${val1} ${val2} ${val3} are too restrictive! Can't find match in ${DIR}."
		    exit 1
		fi
	    done
	done
    done
    reset_ifs
}


greater_than()
{
    local result=`echo "${1} > ${2}"|bc -l`
    if [ ${PIPESTATUS} -eq 0 ];then
	echo ${result}
    else
	echo "ERROR"
    fi
}
less_than()
{
    local result=`echo "${1} < ${2}"|bc -l`
    if [ ${PIPESTATUS} -eq 0 ];then
	echo ${result}
    else
	echo "ERROR"
    fi
}


sanity_checks()
{
    if [ ! -d "${DIR}" ]; then
	echo "ERROR: Directory \"${dir}\" does not exist ! (wrong --dir ???)"
	exit 1
    fi

    if [ "${data_file}" == "" ] || [ "${data_dir}" == "/" ];then
	echo "ERROR: data file == '/'  !!!"
	exit 1
    fi

    local data_file_dir=${data_file%/*}
    if [ ! -d "${data_file_dir}" ]; then
	mkdir -p $data_file_dir
	if [ $? -ne 0 ]; then
	    echo "ERROR: Can't create ${data_file_dir} for ${data_file}."
	    exit 1
	fi
    fi

    check_if_arguments_exist "${x_vals}" "${y_vals}" "${others}" "${DIR}"
    if [ $? -ne 0 ]; then exit 1; fi    

    if [ "${x_norm}" != "" ]&&[ "${y_norm}" ]; then
	echo "ERROR: Can't enable BOTH --xnorm AND --ynorm"
	exit 1
    fi

    if [ "${x_tics_rotate}" != "" ];then
	is_integer ${x_tics_rotate}
	local angle_is_integer=${RETVAL}
	if [ "${angle_is_integer}" == "no" ];then
	    echo "ERROR: X label rotate must be an integer, not: ${x_tics_rotate}."
	    exit 1
	fi
    else
	x_tics_rotate=-60
    fi

    # size is number
    if [ "${size_param}" != "" ];then
	is_number ${size_param_x}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: size of x: ${size_param_x} in size parameter ${size_param} is not a number."
	    exit 1
	fi
	is_number ${size_param_y}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: size of y: ${size_param_y} in size parameter ${size_param} is not a number."
	    exit 1
	fi
	isgt0=`greater_than ${size_param_x} 0`
	if [ "${isgt0}" == "0" ]; then
	    echo "ERROR: Wrong X size: ${size_param_x} of param:${size_param}. Must be > 0."
	    exit 1
	fi
	isgt0=`greater_than ${size_param_y} 0`
	if [ "${isgt0}" == "0" ]; then
	    echo "ERROR: Wrong Y size ${size_param_y} of param:${size_param}. Must be > 0."
	    exit 1
	fi
    fi


    # X,Y tics
    if [ "${x_tics}" != "" ];then
	is_integer ${x_tics}
	local is=${RETVAL}
	if [ "${is}" != "yes" ]; then
	    echo "ERROR: X tics: ${x_tics} must be a positive integer."
	    exit 1
	fi
	if [ ${x_tics} -le 0 ];then
	    echo "ERROR: X tics: ${x_tics} must be a positive integer."
	    exti 1
	fi
    fi

    if [ "${y_tics}" != "" ];then
	is_integer ${y_tics}
	local is=${RETVAL}
	if [ "${is}" != "yes" ]; then
	    echo "ERROR: Y tics: ${y_tics} must be a positive integer."
	    exit 1
	fi
	if [ ${y_tics} -le 0 ];then
	    echo "ERROR: Y tics: ${y_tics} must be a positive integer."
	    exti 1
	fi
    fi


    # yrange
    if [ "${y_range}" != "" ];then
	y_range_min=${y_range_array[0]}
	y_range_max=${y_range_array[1]}
	y_range_step=${y_range_array[2]}
	is_number ${y_range_min}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: in yrange: ${y_range}. ${y_range_min} is not a number."
	    exit 1
	fi
	is_number ${y_range_max}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: in yrange: ${y_range}. ${y_range_max} is not a number."
	    exit 1
	fi

	local isgt=`greater_than ${y_range_max} ${y_range_min}`
	if [ "${isgt}" == "0" ];then
	    echo "ERROR: in yrange:${y_range}. Should be ${y_range_max} > ${y_range_min}."
	    exit 1
	fi

	if [ "${y_range_step}" != "" ];then
	    if [ "${y_tics}" != "" ];then
		echo "ERROR: Conflicting options --ytics ${y_tics} and --yrange ${y_range}."
		exit 1
	    fi
	    is_number ${y_range_step}
	    local is=${RETVAL}
	    if [ "${is}" == "no" ];then
		echo "ERROR: in yrange: ${y_range}. ${y_range_step} is not a number."
		exit 1
	    fi
	fi
    fi

    # colors
    if [ "${user_colors}" != "" ];then
	set_ifs ","
	local color
	for color in ${user_colors}; do
	    local grepped_color=`echo ${color} | egrep -o "#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"`
	    if [ "${grepped_color}" != "${color}" ]; then
		echo "ERROR: in color ${color} of ${user_colors}."
		exit 1
	    fi
	done


	local x
	local xi=0
	for x in ${x_vals}; do
	    xi=$(($xi+1))
	done
	if [ ${xi} -gt ${#color_array[@]} ];then
	    echo "ERROR: Too few colors specified. At least ${xi} are required!"
	    exit 1
	fi

	reset_ifs
    fi

    # cluster gap
    if [ "${cluster_gap}" != "" ];then
	is_number ${cluster_gap}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: cluster gap: ${cluster_gap} must be a number!"
	    exit 1
	fi
	local isgt=`greater_than ${cluster_gap} 0`
	if [ "${isgt}" == "0" ];then
	    echo "ERROR: cluster gap: ${cluster_gap} must be a positive number!"
	    exit 1
	fi
    fi

    # xmap
    if [ "${x_map}" != "" ];then
	local i=0
	local maxi=${#x_map_array[@]}
	while [ ${i} -le ${maxi} ];do
	    local xbit=${x_map_array[${i}]}
	    if [ "${xbit}" != "1" ]&&[ "${xbit}" != "0" ];then
		echo "ERROR: in xmap: ${x_map}. The ${i}'th bit: ${xbit} must be 0 or 1."
		exit 1
	    fi
	done
    fi

    # ymap
    if [ "${y_map}" != "" ];then
	local i=0
	local maxi=${#y_map_array[@]}
	while [ ${i} -le ${maxi} ];do
	    local ybit=${y_map_array[${i}]}
	    if [ "${ybit}" != "1" ]&&[ "${ybit}" != "0" ];then
		echo "ERROR: in ymap: ${y_map}. The ${i}'th bit: ${ybit} must be 0 or 1."
		exit 1
	    fi
	done
    fi

   # xavg
    if [ "${x_avg}" != "" ];then
	local i=0
	local maxi=${#x_avg_array[@]}
	while [ ${i} -lt ${maxi} ];do
	    local x=${x_avg_array[${i}]}
	    is_integer ${y_tics}
	    local is=${RETVAL}
	    if [ "${is}" != "yes" ]; then
		echo "ERROR: in xavg: ${x_avg}. ${x} must be an integer."
		exit 1
	    fi
	    local min=0
	    local max=0
	    local xv
	    for xv in ${x_vals};do
		max=$((${max} + 1))
	    done

	    if [ ${x} -lt ${min} ]||[ ${x} -gt ${max} ];then
		echo "ERROR: in xavg: ${x_avg}. Must be: ${min} < ${x} < ${max}."
		exit 1
	    fi
	    i=$((${i} + 1))
	done
	avg_max_x=${maxi}
    fi

   # yavg
    if [ "${y_avg}" != "" ];then
	local i=0
	local maxi=${#y_avg_array[@]}
	while [ ${i} -lt ${maxi} ];do
	    local y=${y_avg_array[${i}]}
	    is_integer ${y_tics}
	    local is=${RETVAL}
	    if [ "${is}" != "yes" ]; then
		echo "ERROR: in yavg: ${y_avg}. ${y} must be an integer."
		exit 1
	    fi
	    local min=0
	    local max=0
	    local yv
	    for yv in ${y_vals};do
		max=$((${max} + 1))
	    done

	    if [ ${y} -lt ${min} ]||[ ${y} -gt ${max} ];then
		echo "ERROR: in yavg: ${y_avg}. Must be: ${min} < ${y} < ${max}."
		exit 1
	    fi
	    i=$((${i} + 1))
	done
	avg_max_y=${maxi}
    fi

    # bar width
    if [ "${bar_width}" != "" ];then
	is_number ${bar_width}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: bar width: ${bar_width} must be a number!"
	    exit 1
	fi
    else
	if [ "${plot_type}" == "stacked" ]; then
	    bar_width=0.6  		# Default bar width
	fi
    fi
}

get_normalize_values_nums()
{
    local ni
    for yn in ${y_normv}; do
	is_number ${yn}
	local is=${RETVAL}
	if [ "${is}" == "no" ];then
	    echo "ERROR: -ynormv ${y_normv}: ${yn} must be a number!"
	    exit 1
	fi
	y_norm_array[${ni}]=${yn}
	ni=$((${ni} + 1))
    done
}


# Read -xnorm and -ynorm filters and find the values that correspond to them
get_normalize_values()
{
    # If values are given, dont use filters
    if [ "$y_normv" != "" ]||[ "$x_normv" != "" ];then
	return
    fi

    # Normalize
    set_ifs ","
    printf "Getting X normalization values from filters... "
    local ni=0
    local xn
    for xn in ${x_norm};do
	get_match "${DIR}" "${xn} ${others}"
	local file=${RETVAL}
	get_file_value "${DIR}/${file}"
	local xnorm_val=${RETVAL}
	x_norm_array[${ni}]=${xnorm_val}
	ni=$((ni + 1))
    done

    local xi=0
    local x
    for x in ${x_vals};do
	if [ "${x_norm_array[${xi}]}" == "" ];then
	    x_norm_array[${xi}]=${x_norm_array[0]}
	fi
	xi=$((xi + 1))
    done
    
    printf "Done!\n"
    echo "X norm values: ${x_norm_array[@]}"

    printf "Getting Y normalization values from filters... "
    local ni=0
    local yn
    for yn in ${y_norm};do
	get_match "${DIR}" "${yn} ${others}"
	local file=${RETVAL}
	get_file_value "${DIR}/${file}"
	local ynorm_val=${RETVAL}
	y_norm_array[${ni}]=${ynorm_val}
	ni=$((ni + 1))
    done

    local yi=0
    local y
    for y in ${x_vals};do
	if [ "${y_norm_array[${yi}]}" == "" ];then
	    y_norm_array[${yi}]=${y_norm_array[0]}
	fi
	yi=$((yi + 1))
    done
    printf "Done!\n"
    echo "Y norm values: ${y_norm_array[@]}"
    reset_ifs
}

parse_legend()
{
    local ON=0
    local OFF=1
    local OUT=2
    local IN=3
    local TOP=4
    local BOTTOM=5
    local CENTER=6
    local RIGHT=7
    local LEFT=8
    local VERTICAL=9
    local HORIZONTAL=10
    local BOX=11
    local NOBOX=12
    local LJUST=13
    local RJUST=14
    local SMALL=15
    local AT=16


    
    set_ifs ","
    local mask
    local p
    for p in ${legend_params}; do
	case "${p}" in
	    "on") mask[${ON}]=1;;
	    "off") mask[${OFF}]=1;;
	    "out") mask[${OUT}]=1;;
	    "in") mask[${IN}]=1;;
	    "top") mask[${TOP}]=1;;
	    "bottom") mask[${BOTTOM}]=1;;
	    "center") mask[${CENTER}]=1;;
	    "right") mask[${RIGHT}]=1;;
	    "left") mask[${LEFT}]=1;;
	    "vertical") mask[${VERTICAL}]=1;;
	    "horizontal") mask[${HORIZONTAL}]=1;;
	    "box") mask[${BOX}]=1;;
	    "nobox") mask[${NOBOX}]=1;;
	    "ljust") mask[${LJUST}]=1;;
	    "rjust") mask[${RJUST}]=1;;
	    "small") mask[${SMALL}]=1;;
	    *) 
		local atgrep=`echo ${p}|egrep -o "at(([0-9]+)|([0-9]+\.[0-9]+))x(([0-9]+)|([0-9]+\.[0-9]+))"`
		if [ "${p}" == "${atgrep}" ]; then
		    local atcoord=`echo ${atgrep}|sed 's/at//'|sed 's/x/,/'`
		    mask[${AT}]=1
		else
		    echo "Unknown legend option: ${p}"
		    exit 1
		fi
	esac
    done
    reset_ifs

    if [ "${legend_params}" != "" ];then
	mask[${ON}]=1
    fi

    local key_default="set key tmargin"
    local key_start="set key samplen 1"
    key_command=${key_start}
    if [ "${mask[${OFF}]}" == "1" ];then
	key_command="${key_command} off"
    else

	# Exclusive options
	if [ "${mask[${OUT}]}" == "1" ]&&[ "${mask[${IN}]}" == "1" ];then
	    echo "ERROR: Both in,out enabled!"
	    exit 1
	fi
	if [ "${mask[${TOP}]}" == "1" ]&&[ "${mask[${BOTTOM}]}" == "1" ];then
	    echo "ERROR: Both top,bottom enabled!"
	    exit 1
	fi
	if [ "${mask[${RIGHT}]}" == "1" ]&&[ "${mask[${LEFT}]}" == "1" ];then
	    echo "ERROR: Both right,left enabled!"
	    exit 1
	fi
	if [ "${mask[${VERTICAL}]}" == "1" ]&&[ "${mask[${HORIZONTAL}]}" == "1" ];then
	    echo "ERROR: Both vertical,horizontal enabled!"
	    exit 1
	fi
	if [ "${mask[${BOX}]}" == "1" ]&&[ "${mask[${NOBOX}]}" == "1" ];then
	    echo "ERROR: Both box,nobox enabled!"
	    exit 1
	fi


	# Position
	if [ "${mask[${AT}]}" == "1" ];then
	    key_command="${key_command} at ${atcoord}"
	fi


	if [ "${mask[${IN}]}" == "1" ];then
	    key_command="${key_command} inside"
	fi
	if [ "${mask[${OUT}]}" == "1" ];then
	    key_command="${key_command} outside"
	fi


	if [ "${mask[${TOP}]}" == "1" ];then
	    key_command="${key_command} top"
	fi
	if [ "${mask[${BOTTOM}]}" == "1" ];then
	    key_command="${key_command} bottom"
	fi
	if [ "${mask[${CENTER}]}" == "1" ];then
	    key_command="${key_command} center"
	fi


	if [ "${mask[${LEFT}]}" == "1" ];then
	    key_command="${key_command} lmargin"
	fi
	if [ "${mask[${RIGHT}]}" == "1" ];then
	    key_command="${key_command} rmargin"
	fi

	# Sample size
	if [ "${mask[${SMALL}]}" == "1" ];then
	    key_command="${key_command} samplen 1"
	fi





	# Justification
	if [ "${mask[${LJUST}]}" == "1" ];then
	    key_command="${key_command} Left"
	fi
	if [ "${mask[${RJUST}]}" == "1" ];then
	    key_command="${key_command} Right"
	fi



	# Default 
	if [ "${key_command}" == "${key_start}" ];then
	    key_command=${key_default}
	fi


	# Vertical-Horizontal (optional)
	if [ "${mask[${VERTICAL}]}" == "1" ];then
	    key_command="${key_command} vertical"
	fi
	if [ "${mask[${HORIZONTAL}]}" == "1" ];then
	    key_command="${key_command} horizontal"
	fi


	# Box/Nobox
	if [ "${mask[${BOX}]}" == "1" ];then
	    key_command="${key_command} box"
	fi
	if [ "${mask[${NOBOX}]}" == "1" ];then
	    key_command="${key_command} nobox"
	fi


    fi
    echo "Legend: ${key_command}"
}


parse_size()
{
    if [ "${size_param}" != "" ]; then
	set_ifs "xX"
	local s
	local si=0
	local size_array
	for s in ${size_param};do
	    size_array[${si}]=${s}
	    si=$((si + 1))
	done
	reset_ifs
	if [ ${si} -gt 2 ]||[ "${size_array[0]}" == "" ]||[ "${size_array[1]}" == "" ]; then
	    echo "ERROR: parsing size parameter: ${size_param}. Must be: NUMxNUM."
	    exit 1
	fi
	size_param_x=${size_array[0]}
	size_param_y=${size_array[1]}
    fi
}

parse_yrange()
{
    if [ "${y_range}" != "" ];then
	local ni=0
	set_ifs ","
	for num in ${y_range}; do
	    y_range_array[${ni}]=${num}
	    ni=$(($ni + 1))
	done
	reset_ifs
	if [ ${ni} -lt 2 ];then
	    echo "ERROR: yrange: ${y_range} should be a pair: num1,num2"
	    exit 1
	fi
    fi
}

parse_colors()
{
    if [ "${user_colors}" == "" ];then
	color_array[0]="#000000" #(black)
	color_array[1]="#000000" #(black)
	color_array[2]="#000000" # black
	color_array[3]="#FFFF00" # light yellow
	color_array[4]="#0000AA" # dark blue
	color_array[5]="#00BB00" # light green
	color_array[6]="#AA0000" # red
	color_array[7]="#6699ff" # light blue
	color_array[8]="#ffcc00" # light orange
	color_array[9]="#990099" # purple
	color_array[10]="#999900"
	color_array[11]="#dddddd"
	color_array[12]="#555555"
	color_array[13]="#00ff00"
	color_array[14]="#00ffff"
	color_array[15]="#ff0000"
	color_array[16]="#ff00ff"
	color_array[17]="ffff00"
        # dark blue, light orange, dark green, light pink, dark brown, light grey
        #color_array=("#000066" "#ffcc00" "#336600" "#ff66ff" "#660000" "#999999")
    else
	set_ifs ","
	local i=2
	for c in ${user_colors}; do
	    color_array[${i}]="${c}"
	    i=$((i + 1))
	done
	reset_ifs
    fi
}

parse_xmask()
{
    if [ "${x_mask}" != "" ];then
	local x
	local i=0
	set_ifs ", "
	for x in ${x_mask}; do
	    x_mask_array[${i}]=${x}
	    i=$(($i + 1))
	done
	reset_ifs
    fi
}

parse_ymask()
{
    if [ "${y_mask}" != "" ];then
	local y
	local i=0
	set_ifs ", "
	for y in ${y_mask}; do
	    y_mask_array[${i}]=${y}
	    i=$(($i + 1))
	done
	reset_ifs
    fi
}

parse_zmask()
{
    if [ "${z_mask}" != "" ];then
	local z
	local i=0
	set_ifs ", "
	for z in ${z_mask}; do
	    z_mask_array[${i}]=${z}
	    i=$(($i + 1))
	done
	reset_ifs
    fi
}



parse_xavg()
{
    if [ "${x_avg}" != "" ];then
	local x
	local i=0
	set_ifs ", "
	for x in ${x_avg}; do
	    x_avg_array[${i}]=${x}
	    i=$(($i + 1))
	done
	reset_ifs
    fi
}

parse_yavg()
{
    if [ "${y_avg}" != "" ];then
	local y
	local i=0
	set_ifs ", "
	for y in ${y_avg}; do
	    y_avg_array[${i}]=${y}
	    i=$(($i + 1))
	done
	reset_ifs
    fi
}

do_percent()
{
    if [ "${percent}" != "" ];then
	if [ "${y_format}" == "" ];then
	    y_format="%.0f%%"
	fi
	if [ "${y_range}" == "" ];then
	    y_range="0,100,10"
	fi
    fi
}

parse_arguments()
{
    # DIR
    if [ "${DIR}" == "" ];then
	DIR="${PWD}"
	echo "WARNING: No -dir given, assuming \"${DIR}\" "
    fi


    local short_args="hd:x:y:z:f:t:c:i"
    local long_args="help,bar,hmap,line,stack,dir:,xvals:,yvals:,zvals:,filter:,title:,\
xlabel:,ylabel:,wdata:,xtags:,ytags:,ztags:,xnorm:,ynorm:,ynormv:,xrotate:,legend:,size:,\
xformat:,yformat:,ytics:,yrange:,colors:,ignore,gap:,xmask:,ymask:,zmask:,xavg:,yavg:,\
percent,barw:,barlw:,viewer:"
    local args=`getopt -o "${short_args}" -l "${long_args}" -n "getopt.sh" -- "$@"`
    local args_array=($args)
    getopt -q -o "${short_args}" -l "${long_args}" -n "getopt.sh" -- "$@"
    if [ $? != 0 ]||[ "${args_array[0]}" == "--" ] ;then
	echo "Bad argument(s), printing help and exiting."
	usage
	exit 1
    fi
    eval set -- "$args"
    while true; do
	case "$1" in
	    "--dir"|"-dir"|"-d") DIR="$2";shift;;
	    "--xvals"|"-xvals"|"-x") x_vals="$2";shift;;
	    "--yvals"|"-yvals"|"-y") y_vals="$2";shift;;
	    "--zvals"|"-zvals"|"-z") z_vals="$2";shift;;
	    "--filter"|"-filter"|"-f") others="$2";shift;;
	    "--title"|"-title"|"-t") main_title="$2";shift;;
	    "--xtags"|"-xtags") x_tags="$2";shift;;
	    "--ytags"|"-ytags") y_tags="$2";shift;;
	    "--ztags"|"-ztags") z_tags="$2";shift;;
	    "--xlabel"|"-xlabel") x_title="$2";shift;;
	    "--ylabel"|"-ylabel") y_title="$2";shift;;
	    "--help"|"-help"|"-h") usage; exit 1;;
	    "--bar"|"-bar") plot_type="bargraph";;
	    "--hmap"|"-hmap") plot_type="heatmap";;
	    "--line"|"-line") plot_type="linegraph";;
	    "--stack"|"-stack") plot_type="stacked";;
	    "--wdata"|"-wdata") data_file="$2";shift;;
	    "--xnorm"|"-xnorm") x_norm="$2";shift;;
	    "--ynorm"|"-ynorm") y_norm="$2";shift;;
	    "--ynormv"|"-ynormv") y_normv="$2";shift;;
	    "--xrotate"|"-xrotate") x_tics_rotate="$2";shift;;
	    "--legend"|"-legend") legend_params="$2";shift;;
	    "--size"|"-size") size_param="$2";shift;;
	    "--xformat"|"-xformat") x_format="$2";shift;;
	    "--yformat"|"-yformat") y_format="$2";shift;;
	    "--ytics"|"-ytics") y_tics="$2";shift;;
	    "--yrange"|"-yrange") y_range="$2";shift;;
	    "--colors"|"-colors"|"-c") user_colors="$2";shift;;
	    "--ignore"|"-ignore"|"-i") ignore_filter="YES";;
	    "--gap"|"-gap") cluster_gap="$2";shift;;
	    "--xmask"|"-xmask") x_mask="$2";shift;;
	    "--ymask"|"-ymask") y_mask="$2";shift;;
	    "--zmask"|"-zmask") z_mask="$2";shift;;
	    "--xavg"|"-xavg") x_avg="$2";shift;;
	    "--yavg"|"-yavg") y_avg="$2";shift;;
	    "--percent"|"-percent") percent="YES";;
	    "--barw"|"-barw") bar_width="$2";shift;;
	    "--barlw"|"-barlw") bar_line_width="$2";shift;;
	    "--viewer"|"-viewer") eps_viewer="$2";shift;;
	    "--") break;
	esac
	shift
    done
    # Check if plot type is not set. If so default to bargraph
    if [ "${plot_type}XX" == "XX" ];then
	plot_type="bargraph"
    fi

    if [ "${data_file}XX" == "XX" ];then
	data_file="/tmp/moufoplot.data"
    fi


    # Custom Labels (TAGS)
    set_ifs ","
    local xi=0
    for x in ${x_tags}; do
	xtags_array[${xi}]="${x}"
	xi=$((xi+1))
    done
    local yi=0
    for y in ${y_tags}; do
	ytags_array[${yi}]="${y}"
	yi=$((yi + 1))
    done
    local zi=0
    for z in ${z_tags}; do
	ztags_array[${zi}]="${z}"
	zi=$((zi + 1))
    done
    reset_ifs


    # Parse Legend parameters
    parse_legend
    if [ $? -ne 0 ]; then exit 1; fi    

    # Parse Size parameter
    parse_size
    if [ $? -ne 0 ]; then exit 1; fi    

    parse_colors
    if [ $? -ne 0 ]; then exit 1; fi    

    get_normalize_values_nums
    if [ $? -ne 0 ]; then exit 1; fi
    get_normalize_values
    if [ $? -ne 0 ]; then exit 1; fi

    parse_xmask
    if [ $? -ne 0 ]; then exit 1; fi

    parse_ymask
    if [ $? -ne 0 ]; then exit 1; fi

    parse_xavg
    if [ $? -ne 0 ]; then exit 1; fi

    parse_yavg
    if [ $? -ne 0 ]; then exit 1; fi

    do_percent

    parse_yrange
    if [ $? -ne 0 ]; then exit 1; fi    




    echo "+--------------------------------+"
    echo "|         MoufoPlot              |"
    echo "+--------------------------------+"
    echo "| COMMAND LINE OPTIONS:"
    echo "| Type: ${plot_type}"
    echo "| DIR:${DIR}"
    echo "| x: ${x_vals}"
    echo "| y: ${y_vals}"
    echo "| z: ${z_vals}"
    echo "| filter: ${others}"
    echo "| Title: ${main_title}"
    echo "| x label: ${x_title}"
    echo "| y label: ${y_title}"
    echo "| Data file: ${data_file}"
    echo "| xtags: ${x_tags}"
    echo "| ytags: ${y_tags}"
    echo "| ztags: ${z_tags}"
    echo "| x norm filters: ${x_norm}"
    echo "| y norm filters: ${y_norm}"
    echo "| y norm values: ${y_normv}"
    echo "| x tags rotate: ${x_tics_rotate}"
    echo "| Legend: ${legend_params}"
    echo "| Size: ${size_param}"
    echo "| Xformat: ${x_format}"
    echo "| Yformat: ${y_format}"
    echo "| Ytics: ${y_tics}"
    echo "| Yrange: ${y_range}"
    echo "| Colors: ${user_colors}"
    echo "| Ignore Filter ERROR: ${ignore_filter}"
    echo "| Cluster GAP: ${cluster_gap}"

    local xmk
    local xmi=0
    printf "|        "
    for xmk in ${x_mask};do
	printf "%1d " ${xmi}
	xmi=$((${xmi}+1))
	if [ ${xmi} -eq 10 ];then
	    xmi=0
	fi
    done
    printf "\n"
    echo "| xmask: ${x_mask}"

    local ymk
    local ymi=0
    printf "|        "
    for ymk in ${y_mask};do
	printf "%1d " ${ymi}
	ymi=$((${ymi}+1))
	if [ ${ymi} -eq 10 ];then
	    ymi=0
	fi
    done
    printf "\n"
    echo "| ymask: ${y_mask}"

    local zmk
    local zmi=0
    printf "|        "
    for zmk in ${z_mask};do
	printf "%1d " ${zmi}
	zmi=$((${zmi}+1))
	if [ ${zmi} -eq 10 ];then
	    zmi=0
	fi
    done
    printf "\n"
    echo "| zmask: ${z_mask}"


    local argfname=`echo ${data_file}|sed s'/\///g'`
    gpfname="${argfname}.gp"
    epsfile="${argfname}.eps"


    if [ "${bar_line_width}" == "" ];then
	bar_line_width=1
    fi

    echo "| xavg: ${x_avg}"
    echo "| yavg: ${y_avg}"
    echo "| percent: ${percent}"
    echo "| bar width: ${bar_width}"
    echo "| bar line width: ${bar_line_width}"
    echo "| .gp  file: ${gpfname}"
    echo "| .eps file: ${epsfile}"
    echo "| viewer: ${eps_viewer}"
    echo "+-------------------------------+"

}


usage()
{
    script_name=${0##*/}
    echo "Usage: ${script_name} <OPTIONS>"
    echo "   --bar                        : (DEF) Generate histograms."
    echo "   --stack                      : Generate stacked histograms."
    echo "   --line                       : Generate line-graphs."
    echo "   --hmap                       : Generate heat-map graphs."
    echo "   --dir,-d \"<DIR>\"           : The result files Directory."
    echo "   --xvals,-x \"<x values>\"    : The identifiers of the X values."
    echo "   --yvals,-y \"<y values>\"    : The identifiers of the Y values."
    echo "   --zvals,-z \"<z values>\"    : The identifiers of the Z values."
    echo "   --filter,-f \"<filter vals>\": The filtering identifiers."
    echo "   --title, -t \"<title>\"      : (Opt) Graph title."
    echo "   --xlabel \"<x label>\"       : (Opt) Label of the X axis."
    echo "   --ylabel \"<y label>\"       : (Opt) Label of the Y axis."
    echo "   --w-data \"<file path>\"     : (Opt) Path of data file."
    echo "   --xtags \"<tags>\"           : (Opt) Tags for the X axis."
    echo "   --ytags \"<tags>\"           : (Opt) Tags for the Y axis."
    echo "   --ztags \"<tags>\"           : (Opt) Tags for the Z axis."
    echo "   --xnorm \"<x norm filters>\" : (Opt) Normalization filter X."
    echo "   --ynorm \"<y norm filters>\" : (Opt) Normalization filter Y."
    echo "   --ynormv \"<y norm values>\" : (Opt) Normalization values Y."
    echo "   --xrotate \"<angle>\"        : (Opt) Rotate angle for X tags."
    echo "   --legend \"<parameters>\"    : (Opt) Control legend attrib."
    echo "         Params: on/off, in/out, top/bottom/center, right/left,"
    echo "                 horizontal/vertical, ljust,rjust, small, box, atMxN"
    echo "   --size NUMxNUM               : (Opt) Dimensions of the graph."
    echo "   --xformat \"format\"         : (Opt) Format of the x tags."
    echo "   --yformat \"format\"         : (Opt) Format of the y tags."
    echo "   --ytics NUM                  : (Opt) Number of tics on Y."
    echo "   --yrange MIN,MAX,STEP        : (Opt) Range of Y tics."
    echo "   --colors,-c #color1,#color2..: (Opt) User defined colors."
    echo "   --gap <number>               : (Opt) The gap between clusters."
    echo "   --xmask <bitmap>             : (Opt) Disable X bars with 0."
    echo "   --ymask <bitmap>             : (Opt) Disable Y bars with 0."
    echo "   --zmask <bitmap>             : (Opt) Disable Z bars with 0."
    echo "   --xavg <array of X>          : (Opt) Avg over selected X."
    echo "   --yavg <array of Y>          : (Opt) Avg over selected Y."
    echo "   --ignore,-i                  : (Opt) Ignore Filter ERROR."
    echo "   --percent                    : (Opt) Change Y axis to show % vals."
    echo "   --viewer <eps viewer>        : (Opt) Prefer to use EPS VIEWER."
    echo "   --barw <bar width>           : (Opt) Set the bar width size."
    echo "   --barlw <bar line width>     : (Opt) Set the bar line width."
    echo "   --help                       : Print this help screen."
    exit 1
}

findviewer()
{
    local pdfviewers="evince,okular,kpdf,gv,inkscape,gimp"
    if [ "${eps_viewer}" != "" ];then
	pdfviewers="${eps_viewer},${pdfviewers}"
    fi
    local viewer
    RETVAL=""
    set_ifs ","
    for viewer in ${pdfviewers}; do
	which ${viewer} 2> /dev/null 1> /dev/null
	if [ $? -eq 0 ];then
	    RETVAL=${viewer}
	    reset_ifs
	    return
	fi
    done
    echo "WARNING: No EPS viewer found in (${pdfviewers}) to display ${epsfile}."
    echo "Try using: --viewer " 
    reset_ifs
}


moufoplot()
{
    IFS_CNT=0
    IFS_CHAR=','
    parse_arguments "$@"
    if [ $? -ne 0 ]; then exit 1; fi

    sanity_checks
    if [ $? -ne 0 ]; then exit 1; fi

    if [ "${plot_type}" == "heatmap" ];then
	create_heatmap_data_file "${data_file}" "${others}"
	gp_heatmap_options "${data_file}" "${x_vals}" "${y_vals}" "${main_title}" "${x_title}" "${y_title}"
    elif [ "${plot_type}" == "bargraph" ];then
	create_data_file "${data_file}" "${others}"
	gp_bar_options
    elif [ "${plot_type}" == "linegraph" ];then
	create_data_file "${data_file}" "${others}"
	gp_line_options "${data_file}" "${x_vals}" "${y_vals}" "${main_title}" "${x_title}" "${y_title}"
    elif [ "${plot_type}" == "stacked" ];then
	create_data_file "${data_file}" "${others}"
	gp_bar_options "rowstacked"
    fi

    # View EPS file
    findviewer
    local viewer=${RETVAL}
    if [ "${viewer}" != "" ];then
	echo "View ${epsfile} using ${viewer}"
	local viewcmd="${viewer} ${epsfile}"
	eval ${viewcmd}
    fi
}

moufoplot "$@"

