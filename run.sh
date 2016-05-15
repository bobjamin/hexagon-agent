#!/bin/sh
. yaml-parser.sh
echo Parsing Configuration
eval $(parse_yaml /config/config.yml "config_")
echo Configuration Parsed

if [ -z "$BUILD" ]; then
  echo No build number found! Please set the BUILD environment vairable.
  exit 1
fi
echo Build $BUILD found
echo Searching for self
AGENTID=$(cat /etc/hosts | grep $(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}') | awk '{ print $2}')

if [ -z "$AGENTID" ]; then
  echo Container could not be found.
  exit 1
fi

echo Found self as container id $AGENTID

run_task(){
  XTASK=config_tasks_task$1
  XTASKNAME=''$XTASK'_name'
  XVARCOUNT=''$XTASK'_varcount'

  VARCOUNT=$(eval echo \"'$'$XVARCOUNT\")
  TASKNAME=$(eval echo \"'$'$XTASKNAME\")

  echo Running task $1 : $TASKNAME

  variable=0
  VARCOMMAND=''
  while [ $variable -lt $VARCOUNT ]
  do
   curvariable=`expr $variable + 1`

   XVARIABLE=''$XTASK'_var'$curvariable
   XVARNAME=''$XVARIABLE'_name'
   XVARVALUE=''$XVARIABLE'_value'

   VARNAME=$(eval echo \"'$'$XVARNAME\")
   VARVALUE=$(eval echo \"'$'$XVARVALUE\")

   APPENDCOMMAND=" -e "$VARNAME'='$VARVALUE

   VARCOMMAND="$VARCOMMAND""$APPENDCOMMAND"

   variable=`expr $variable + 1`
   done
   eval $(echo docker run --rm --volumes-from $AGENTID"$VARCOMMAND" $TASKNAME)
}

echo Number of tasks to run: $config_tasks_taskcount

task=0
while [ $task -lt $config_tasks_taskcount ]
do
   run_task `expr $task + 1`
   task=`expr $task + 1`
done

# Example config.yml for a build that clones a git repo
#build: 1
#tasks:
#  taskcount: 1
#  task1:
#    name: git-cloner
#    varcount: 1
#    var1:
#      name: URL
#      value: https://github.com/bobjamin/hello-world.git
