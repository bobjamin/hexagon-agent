#!/bin/sh
. yaml-parser.sh
echo Parsing Configuration
eval $(parse_yaml /config/config.yml "config_")
echo Configuration Parsed

if [ -z "$config_build" ]; then
  echo No build number found! Please add a build entry into the config.yml file.
  exit 1
fi
echo Build $config_build found
echo Checking agent is configured with correct name for build
agentcontainerid=$(eval docker ps -q -f name=agent-build$config_build)
AGENTNAME='agent-build'$config_build

if [ -z "$agentcontainerid" ]; then
  echo Container is not named correctly. Name the container $AGENTNAME
  exit 1
fi

echo Found self as container id $agentcontainerid and with the name $AGENTNAME

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
   echo "$VARCOMMAND"
   echo Running $TASKNAME
   eval $(echo docker run --volumes-from $AGENTNAME"$VARCOMMAND" $TASKNAME)
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
