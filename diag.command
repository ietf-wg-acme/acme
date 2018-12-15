#!/bin/sh

cwd=`dirname "$0"`
cd "$cwd"

## Set app name
APP_NAME=rekordbox

## Set search path
USER_LIBRARY_LOG_DIR_ARRAY=(~/Library/Logs/DiagnosticReports)
ROOT_LIBRARY_LOG_DIR_ARRAY=(/Library/Logs/DiagnosticReports)

## Set Exception Directory path
USER_EXCEPTION_INFO_DIR=~/Library/Pioneer/rekordbox/Exceptions

## time
CURRENT_TIME=`date +"%Y%m%d%H%M"`

## temporary folder
OUTPUT_FOLDER_NAME=${APP_NAME}_${CURRENT_TIME}
OUTPUT_ROOT_FOLDER_PATH=~/Desktop/${OUTPUT_FOLDER_NAME}


## start
echo "**********"
echo "START DIAG"
echo "**********"

# create folder
mkdir $OUTPUT_ROOT_FOLDER_PATH

# copy exception info
ls $USER_EXCEPTION_INFO_DIR >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "[Exception ] no  ($USER_EXCEPTION_INFO_DIR)"
else
	# copy
	echo "[Exception ] yes"

	cp -r $USER_EXCEPTION_INFO_DIR $OUTPUT_ROOT_FOLDER_PATH/
fi

# Search & copy User Library Logs
for ((i = 0; i < ${#USER_LIBRARY_LOG_DIR_ARRAY[@]}; i++)) {
	#echo "USER_LIBRARY_LOG_DIR_ARRAY[$i] = ${USER_LIBRARY_LOG_DIR_ARRAY[i]}"

	ls ${USER_LIBRARY_LOG_DIR_ARRAY[i]}/*$APP_NAME* >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "[Crash_User] no  (${USER_LIBRARY_LOG_DIR_ARRAY[i]})"
	else
		# make temporary folder
		echo "[Crash_User] yes (${USER_LIBRARY_LOG_DIR_ARRAY[i]})"

		TEMPORARY_FOLDER=$OUTPUT_ROOT_FOLDER_PATH/USER$i
		mkdir -p $TEMPORARY_FOLDER
		cp ${USER_LIBRARY_LOG_DIR_ARRAY[i]}/*$APP_NAME* $TEMPORARY_FOLDER/
	fi
}

# Search & copy Root Library Logs
for ((i = 0; i < ${#ROOT_LIBRARY_LOG_DIR_ARRAY[@]}; i++)) {
	#echo "ROOT_LIBRARY_LOG_DIR_ARRAY[$i] = ${ROOT_LIBRARY_LOG_DIR_ARRAY[i]}"
	
	ls ${ROOT_LIBRARY_LOG_DIR_ARRAY[i]}/*$APP_NAME* >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "[Crash_Sys ] no  (${ROOT_LIBRARY_LOG_DIR_ARRAY[i]})"
	else
		# make temporary folder
		echo "[Crash_Sys ] yes (${ROOT_LIBRARY_LOG_DIR_ARRAY[i]})"

		TEMPORARY_FOLDER=$OUTPUT_ROOT_FOLDER_PATH/SYS$i
		mkdir -p $TEMPORARY_FOLDER
		cp ${ROOT_LIBRARY_LOG_DIR_ARRAY[i]}/*$APP_NAME* $TEMPORARY_FOLDER/
	fi
}

# zip folder
cd $OUTPUT_ROOT_FOLDER_PATH/../
zip -rmq ${OUTPUT_FOLDER_NAME}.zip ${OUTPUT_FOLDER_NAME}


## finish
echo ""
echo "${OUTPUT_FOLDER_NAME}.zip was created in your desktop."

echo "********"
echo "END DIAG"
echo "********"
