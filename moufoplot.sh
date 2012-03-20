#!/bin/bash
color_array=("#000000" "#000099" "#009900" "#009999" "#990000" "#990099" "#999900" "#dddddd" "#555555" "#00ff00" "#00ffff" "#ff0000" "#ff00ff" "ffff00")
DIR=$1
XAXIS=$2
GROUP=$3

# Input: FILE
# Output: A string with all the parts separated by space
# Example: get_all_parts_of_file jpeg_otp1_i1_d2
#          Returns: "jpeg opt1 i1 d2"
get_all_parts_of_file()
{
    local f=$1
    local parts=`echo $f |egrep -o [[:alnum:]-]+`
    echo $parts
}


# Input: FILE PART_NUM
# Output: The value of the PART_NUM part of FILE
# Example: get_part_of_file jpeg_opt1_i1_d2 1 
#          Returns: opt1
get_part_of_file()
{
    local f=$1
    local part=$2
    local parts=(`get_all_parts_of_file $f`)
    echo ${parts[$part]}
}


# Input: FILE
# Output: The number of parts in FILE
# Example: count_parts jpeg_opt1_i1_d2
#         Returns: 4
count_parts()
{
    local f=$1
    local p=`get_all_parts_of_file $f`
    local parts_cnt=`echo $p|wc -w`
    echo ${parts_cnt}
}

# Input: DIR
# Output: The number of parts that each file has in DIR
# Example: check_parts data/  (where data contains files like <benc*>_<opt*>_<i*>_<d*>)
#          Returns 4
check_parts()
{
    local DIR=$1
    local first_file=`ls -1 $DIR|head -n 1`
    local last_cnt=`count_parts ${first_file}`
    local files=`ls -1 $DIR`
    for f in $files; do
	# echo $f
	local cnt=`count_parts $f`
	# echo $cnt
	if [ ${cnt} -ne ${last_cnt} ]; then
	    echo "$f has ${cnt} parts !!! It should have ${last_cnt} parts!!!"
	    exit 1
	fi
	last_cnt=$cnt
    done
    echo $last_cnt
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
	part_value=`get_part_of_file $f $part`
	local found=0
	for val in ${all_values}; do
	    if [ "$val" == "${part_value}" ];then
		found=1
	    fi
	done
	if [ $found -eq 0 ]; then
	    all_values="${all_values} ${part_value}"
	fi
    done
    echo ${all_values}

    
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
	if [ $needle -eq $hay ]; then
	    found=1
	fi
    done
    echo $found
}

# Input: FIRST_NUM END_NUM NAME_PREFIX
# Output: the figure names
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
    # for val in `get_all_values_in_part "$DIR" $i`;do
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
    local grep_cmd=""
    for match in $matches; do
	grep_cmd="${grep_cmd}|egrep \"_${match}_|^${match}_|_${match}\\$\""
    done
    grep_cmd="ls -1 ${DIR}${grep_cmd}"
    # echo $grep_cmd
    local filename=`eval ${grep_cmd}`
    local count_files=`echo $filename|wc -w`
    if [ ${count_files} -ne 1 ]; then
    	echo "ERROR!!! ${count_files} files detected with the given options: $matches"
    	echo -e "$filename"
    	echo $grep_cmd
    	echo "This is usually caused by some parameters being exclusive."
	echo "Example: d3 is exclusive to jpeg_i1: jpeg_i1_d3 but NO mpeg_i1_d3."
    	exit 1
    fi
    echo $filename
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
    cat $file
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


gp_options()
{
    local columns=$2
    local data_columns=$3
    data_columns=$((data_columns+1)) #since we start at column 2

# the yrange for each row starting from row 0 
    local Y_RANGE_ENABLED=0
    # local yrange_row=(0:4.7 0:4.3 0:6.5 0:4 0:3 0:3 0:7) # Lowest first
    local size_x=0.75
    local size_y=0.8
#bottom_margin=`echo "${size_y}/2.0" |bc -l`
    local bottom_margin=0.01
    local KEYSTUFF="inside top"
    local LW=7
    local POINTSIZE=3
    local LEG_X=0
    local LEG_Y=0
    local gpcol="COL=2:${data_columns}" # due to x axis on column 1

    local boxwidth=0.2

    # local yrange="0.5:"
    # local ytitle="Normalized cycles"
    # local xtitle="Issue-Width per Core"


    local FONTSIZE="38"

    local KEYFONTSIZE="34"
    local KEYFONTSPACING="3.7"
    local TICSFONTSIZE="30"

    local XLABELOFFSET="0"
    local YLABELOFFSET="0"
    local LABELFONTSIZE=$FONTSIZE
    local LABELFONTSIZE="28"

    if [ $# -ne 3 ]; then
	echo "Usage: $0 path/ <columns> <data columns>"
	exit 1
    fi


    local argfname=`echo $1|sed s'/\///g'`
    local gpfname="${argfname}.gp"
    echo "Generating ${gpfname} . $gpcol, boxwidth=$boxwidth, yrange_enabled=${Y_RANGE_ENABLED}, yrange=${yrange}, lw=$LW, x:$xtitle, y:$ytitle, legend=(${LEG_X},${LEG_Y}), legend:$KEYSTUFF."
    local FILE="${gpfname}"


    local size="$size_x,$size_y"

    local DIR=$1

    local num=0
    for f in `ls -1 $DIR`;do
	num=$(($num + 1))
    done
    local rows=$(($num / $columns))

    local epsfile="${argfname}.eps"
    echo "set term postscript eps enhanced color" > $FILE 
    echo "set output \"${epsfile}\"" >>$FILE
    echo "set boxwidth $boxwidth" >> $FILE
    echo "unset ylabel" >> $FILE
    echo "set xtics 1" >>$FILE
# echo "set ytics 1" >>$FILE
    echo " " >> $FILE
    echo "set key $KEYSTUFF" >> $FILE
    echo " " >> $FILE
    echo "set size  `echo \"$columns * $size_x\"|bc`,`echo \"$rows * $size_y + $bottom_margin\"|bc`" >> $FILE
    echo "set multiplot" >> $FILE
    echo "set tics font \"Times,$TICSFONTSIZE\""  >> $FILE
    echo "set key font \"Times,$KEYFONTSIZE\" spacing $KEYFONTSPACING">> $FILE

    local col=0
    local row=0
    for f in `ls -1 $DIR`; do
	if [ $col -eq $columns ]; then
	    col=0
	    row=$(($row + 1))
	fi
	local f=`echo ${f} | sed s'/$DIR//' `
	local fname=`echo ${f} |sed s'/_/-/g'`
	echo " " >> $FILE
	echo "set title \"{${fname}}\" font \"Times,$FONTSIZE\"" >> $FILE
	echo "set size $size" >> $FILE
	echo "set origin `echo \"$col * $size_x\"|bc`,`echo \"$row * $size_y + $bottom_margin\"|bc`" >> $FILE
    # echo "set pointsize 3" >> $FILE
    # echo "set style line 6 lt 7">> $FILE

	echo "set boxwidth 1 relative" >> $FILE
	echo "set style data histograms" >> $FILE

	echo "set style histogram cluster gap 1" >> $FILE
	echo "set style fill solid 1.0 border lt \"black\"" >> $FILE
	echo "set grid ytics ls 10 lt rgb \"black\"" >> $FILE

	if [ ${Y_RANGE_ENABLED} -eq 1 ]; then
	    echo "set yrange[${yrange_row[$row]}] ">> $FILE
	fi


    # x,y titles

	if [ $col -eq 0 ]; then
	    echo "set ylabel \"${ytitle}\" font \"Times,$LABELFONTSIZE\" offset $YLABELOFFSET" >> $FILE
	else
	    echo "unset ylabel">> $FILE
	fi	
	if [ $row -eq 0 ]; then
	    echo "set xlabel \"${xtitle}\" font \"Times,$LABELFONTSIZE\" offset $XLABELOFFSET" >>$FILE
	else
	    echo "unset xlabel">> $FILE
	fi
	# echo "plot for [${gpcol}] \"${DIR}/${f}\" using 1:COL with linespoints $TITLE lw $LW ps $POINTSIZE lt COL pt COL" >> $FILE
	# echo "plot for [${gpcol}] \"${DIR}/${f}\" using COL:xticlabels(1) " >> $FILE

    # crappy code for fixing the xtics disposition when notitle
	# if [ $col -eq ${LEG_X} ] && [ $row -eq ${LEG_X} ]; then
	#     if [ "${TITLE}" == "notitle" ]; then
	# 	echo "set xtics offset -9" >> $FILE
	# 	echo "set xrange [:4.5]" >> $FILE
	#     else
	# 	echo "set xtics nooffset" >> $FILE
	#     fi
	#     echo "plot for [${gpcol}] \"${DIR}/${f}\" using COL:xtic(1) ${TITLE} " >> $FILE
	# else
	#     if [ "${TITLE}" == "notitle" ]; then
	# 	echo "set xtics offset -7" >> $FILE
	# 	echo "set xrange [:4.5]" >> $FILE
	#     else
	# 	echo "set xtics nooffset" >> $FILE
	#     fi

	#     echo "plot for [${gpcol}] \"${DIR}/${f}\" using COL:xtic(1) ${TITLE} " >> $FILE
	# fi

	# echo "plot for [${gpcol}] \"${DIR}/${f}\" using COL:xtic(1) ${TITLE}" >> $FILE

	local cmn=2
	local plot_cmd="plot "
	while [ $cmn -lt ${data_columns} ]; do
    # Legend control
	    if [ $col -eq ${LEG_X} ] && [ $row -eq ${LEG_Y} ]; then
		local TITLE="title columnheader(${cmn})"
	    else
	    # local TITLE="notitle"
		local TITLE="title columnheader(${cmn})"
	    fi
	    local color=${color_array[$cmn]}
	    plot_cmd="${plot_cmd} \"${DIR}/${f}\" using ${cmn}:xtic(1) $TITLE fc rgb \"${color}\""
	    cmn=$((cmn + 1))
	    if [ $cmn -lt ${data_columns} ]; then
		plot_cmd="${plot_cmd}, "
	    fi
	done
	echo "${plot_cmd}" >> $FILE

	# echo "plot for [${gpcol}] \"${DIR}/${f}\" using COL:xtic(1) ${TITLE}" >> $FILE

	col=$(($col + 1))
    done
    echo "Running \"gnuplot ${gpfname}\" to generate ${epsfile}..."
    gnuplot ${gpfname}

}




parts_cnt=`check_parts $DIR`
echo "Each file in $DIR contains ${parts_cnt} parts"

i=0
while [ $i -lt ${parts_cnt} ];do
    val_array[$i]=`get_all_values_in_part "$DIR" $i`
    i=$((i+1))
done

x_values=$2
x_values_array=($x_values)
# Sanity checks
x_selected=`echo ${x_values}|wc -w`
if [ ${x_selected} -gt 2 ]; then
    echo "Too many parts (${x_selected}) selected for the X Axis: \"${x_values}\"!. Maximum allowed is 2."
    exit 1
fi
for x in ${x_values}; do
    if [ $x -ge ${parts_cnt} ]; then
	echo "WRONG value $x in \"${x_values}\". It should be less than ${parts_cnt}!"
	exit 1
    fi
done


not_x_values=`get_not_x "${x_values}" ${parts_cnt}`
echo ${not_x_values}
all_figs=`gen_names 0 4 "" "${x_values}"`
echo ${all_figs}
all_x=`gen_names 0 4 "" "${not_x_values}"`
echo ${all_x}

data_file_prefix="cycles"
data_dir="/tmp/moufoplot/"
if [ "${data_dir}" == "" ] || [ "${data_dir}" == "/" ];then
    echo "ERROR!!! Trying to delete /  !!!"
    exit 1
fi
rm ${data_dir}/*
mkdir -p $data_dir
data="X"
data_file_array=""
for fig in ${all_figs}; do
    data_filename="${data_dir}/${data_file_prefix}$fig"
    data_file_array="${data_file_array} ${data_filename}"
    echo $data_filename
    echo "----------------------"
    fig_options=`get_all_parts_of_file ${fig}`
    xi=${x_values_array[1]}
    for x in ${val_array[$xi]}; do
	data="${data} $x"
    done
    data="${data}\n"
    yi=${x_values_array[0]}
    for y in ${val_array[$yi]}; do
	data="${data}$y"
	for x in ${val_array[$xi]}; do
	    opts="${fig_options} ${x} ${y}"
	    # echo $opts
	    file=`get_match "$DIR" "$opts"`
	    if [ $? -eq 1 ];then
		get_match "$DIR" "$opts"
		exit 1
	    fi
	    # echo ${file}
	    file_val=`get_file_value "$DIR/$file"`
	    # echo ${file_val}
	    data="${data} ${file_val}"
	done
	data="${data}\n"
    done
    echo -e $data |tee ${data_filename}
    data="X"
done

echo "List of data files:"
echo $data_file_array

xtitle="X axis"
ytitle="Y axis"
data_columns=`echo ${val_array[${x_values_array[1]}]}|wc -w`
echo ${data_columns}
gp_options ${data_dir} 2 ${data_columns}