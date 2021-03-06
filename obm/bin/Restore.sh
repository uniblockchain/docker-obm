#!/bin/sh
# Ahsay Online Backup Manager 6.29.0.0

#################################  Restore.sh  #################################
# You can use this shell script to restore backup files using command-line.    #
# Just customize the "User Define Section" below with values for your restore  #
# action.                                                                      #
################################################################################

#########################  Start: User Defined Section  ########################

# -------------------------------  BACKUP_SET  ---------------------------------
# | The name or ID of the backup set that you want to restore                  |
# | If backup set name is not in English, please use BackupSetID               |
# | e.g. BACKUP_SET="1119083740107"                                            |
# |  or  BACKUP_SET="FileBackupSet-1"                                          |
# |                                                                            |
# | You can leave this parameter blank if you have only 1 backup set.          |
# ------------------------------------------------------------------------------
BACKUP_SET=""

# -------------------------------  RESTORE_TO  ---------------------------------
# | Directory to where you want files to be restored                           |
# | set to "" to restore files to original location                            |
# | e.g. RESTORE_TO="/tmp"                                                     |
# ------------------------------------------------------------------------------
RESTORE_TO=""

# ------------------------------  RESTORE_FROM  --------------------------------
# | File/Directory on the backup server that you would like to restore         |
# | e.g. RESTORE_FROM="/Data"                                                  |
# ------------------------------------------------------------------------------
RESTORE_FROM=""

# -----------------------------  POINT_IN_TIME  --------------------------------
# | The point-in-time snapshot (successful backup) that you want to restore    |
# | from the backup server. Use "Current" for the latest backup snapshot       |
# | e.g. POINT_IN_TIME="2006-10-04-12-57-13"                                   |
# |  or  POINT_IN_TIME="Current"                                               |
# |                                                                            |
# | You can retrieve the point in time by using the ListBackupJob.sh           |
# ------------------------------------------------------------------------------
POINT_IN_TIME="Current"

# --------------------------  RESTORE_PERMISSION  ------------------------------
# | set to "Y" if you want to restore file permissions                         |
# | set to "N" if you do NOT want to restore file permissions                  |
# ------------------------------------------------------------------------------
RESTORE_PERMISSION="N"

# ----------------------------  SKIP_INVALID_KEY  ------------------------------
# | set to "Y" if you want to skip restore file with invalid key               |
# | set to "N" if you want to prompt user to input a correct key               |
# ------------------------------------------------------------------------------
SKIP_INVALID_KEY="N"

# ------------------------------  SYNC_OPTION  ---------------------------------
# | Delete extra files                                                         |
# | set to "Y" if you want to enable sync option                               |
# | set to "N" if you do NOT want to enable sync option                        |
# | set to "" to prompt for selection                                          |
# ------------------------------------------------------------------------------
SYNC_OPTION="N"

# -------------------------  REPLACE_EXISTING_FILE  ----------------------------
# | set to "-all" to replace all existing file(s) of the same filename         |
# | set to "-none" to skip all existing file(s) with the same filename         |
# | set to "" to prompt for selection                                          |
# ------------------------------------------------------------------------------
REPLACE_EXISTING_FILE="-all"

# ------------------------------  SETTING_HOME  --------------------------------
# | Directory to your setting home.                                            |
# | Default to ${HOME}/.obm when not set.                                      |
# | e.g. SETTING_HOME="${HOME}/.obm"                                           |
# ------------------------------------------------------------------------------
SETTING_HOME=""

# ---------------------------------  FILTER  -----------------------------------
# | Filter out what files you want to restore                                  |
# | -Pattern=xxx-Type=yyy-Target=zzz                                           |
# | where xxx is the filter pattern,                                           |
# |       yyy is the filter type, whice can be one of the following:           |
# |           [exact | exactMatchCase | contains | containsMatchCase|          |
# |            startWith | startWithMatchCase | endWith | endWithMatchCase]    |
# |       zzz is the filter target, which can be one of the following:         |
# |           [toFile | toFileDir | toDir]                                     |
# |                                                                            |
# | e.g. FILTER="-Pattern=.txt-Type=exact-Target=toFile"                       |
# ------------------------------------------------------------------------------
FILTER=""

##########################  END: User Defined Section  #########################

################################################################################
#      R E T R I E V E            A P P _ H O M E           P A T H            #
################################################################################

EXE_DIR=`pwd`
SCRIPT_HOME=`dirname "$0"`
cd "$SCRIPT_HOME"
APP_BIN=`pwd`
APP_HOME=`dirname "$APP_BIN"`

################################################################################
#      R E T R I E V E           J A V A _ H O M E           P A T H           #
################################################################################

if [ "Darwin" = `uname` ]; then
    JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
fi

if [ ! -x "$APP_HOME/jvm" ];
then
    echo "'$APP_HOME/jvm' does not exist!"
    if [ ! -n "$JAVA_HOME" ]; then
        echo "Please set JAVA_HOME!"
        exit 0
    else
        ln -sf "$JAVA_HOME" "$APP_HOME/jvm"
        echo "Created JAVA_HOME symbolic link at '$APP_HOME/jvm'"
    fi
fi

if [ ! -x "$APP_HOME/jvm" ];
then
    echo "Please create symbolic link for '$JAVA_HOME' to '$APP_HOME/jvm'"
    exit 0
fi

JAVA_HOME="$APP_HOME/jvm"
JAVA_EXE="$JAVA_HOME/bin/java"

# Verify the JAVA_EXE whether it can be executed or not.
if [ ! -x "${JAVA_EXE}" ]
then
    echo "The Java Executable file \"${JAVA_EXE}\" cannot be executed. Exit \""`basename "$0"`"\" now."
    exit 1
fi

# Verify the JAVA_EXE whether it is a valid JAVA Executable or not.
STRING_JAVA_VERSION="java version,openjdk version"
OUTPUT_JAVA_VERSION=`"${JAVA_EXE}" -version 2>&1`
OUTPUT_JVM_SUPPORT=0
BACKUP_IFS=$IFS
IFS=","
for word in $STRING_JAVA_VERSION; do
    if [ `echo "${OUTPUT_JAVA_VERSION}" | grep "${word}" | grep -cv "grep ${word}"` -le 0 ]
    then
      #echo "The Java Executable \"${JAVA_EXE}\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
      continue;
    else
      OUTPUT_JVM_SUPPORT=1
      break;
    fi
done
IFS=$BACKUP_IFS
if [ $OUTPUT_JVM_SUPPORT -eq 0 ]
then
    echo "The Java Executable \"${JAVA_EXE}\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
    exit 1
fi


################################################################################
#                  J A V A                 E X E C U T I O N                   #
################################################################################

# The Restore Action must be execute at path $APP_HOME/bin
cd "${APP_BIN}"

LD_LIBRARY_PATH="$APP_BIN"

DEP_LIB_PATH="X64"
case "`uname -m`" in
    i[3-6]86)
        DEP_LIB_PATH="X86"
    ;;
esac
LD_LIBRARY_PATH="${APP_BIN}/${DEP_LIB_PATH}":"${LD_LIBRARY_PATH}"

SHLIB_PATH="$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH SHLIB_PATH

# Reference path will be used to avoid empty space in the parent directory
LIB_HOME=.
JAVA_OPTS="-Xms128m -Xmx768m"
JNI_PATH="-Djava.library.path=$LIB_HOME"
CLASSPATH="$LIB_HOME:$LIB_HOME/obc.jar:$LIB_HOME/obc-lib.jar"
MAIN_CLASS=Restore

echo "Using APP_HOME:          : ${APP_HOME}"
echo "Using BACKUP_SET         : ${BACKUP_SET}"
echo "Using RESTORE_FROM       : ${RESTORE_FROM}"
echo "Using RESTORE_TO         : ${RESTORE_TO}"
echo "Using POINT_IN_TIME      : ${POINT_IN_TIME}"
echo "Using RESTORE_PERMISSION : ${RESTORE_PERMISSION}"

# Do not include double-quote for java options, jni path, classpath and
# main class.
# Only apply double-quote for path to java executable and execution arguments
"${JAVA_EXE}" $JAVA_OPTS $JNI_PATH -cp $CLASSPATH $MAIN_CLASS -to="${RESTORE_TO}" -from="${RESTORE_FROM}" -backupset="${BACKUP_SET}" "${REPLACE_EXISTING_FILE}" -date="${POINT_IN_TIME}" -setPermission="${RESTORE_PERMISSION}" -skipInvalidKey="${SKIP_INVALID_KEY}" -sync="${SYNC_OPTION}" -Filter="${FILTER}" -AppHome="${APP_HOME}" -SettingHome="${SETTING_HOME}"

################################################################################
#                   R E S E T          A N D          E X I T                  #
################################################################################

cd "${EXE_DIR}"
exit 0
