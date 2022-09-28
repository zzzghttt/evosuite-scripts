#!/bin/bash

#setopt EXTENDED_GLOB

#---------------------------------------------------------------------------------------
#---------------  Change this area to your local Evosuite path   -----------------------
#---------------------------------------------------------------------------------------
EVOSUITE="java -jar /Users/chenyi/Documents/Idea/evoTest/Evosuite/evosuite-1.2.0.jar"

#---------------------------------------------------------------------------------------
#----------------------- Change path where to store project ----------------------------
#---------------------------------------------------------------------------------------
MYPATH="/Users/chenyi/Documents/Idea/evoTest"

#---------------------------------------------------------------------------------------
#------------------- arguments pass to Evosuite (dont need to change) ------------------
#---------------------------------------------------------------------------------------
ARGS="-Doutput_variables=TARGET_CLASS,criterion,Size,Length,Coverage,BranchCoverage,CBranchCoverage,LineCoverage,MethodCoverage,MethodNoExceptionCoverage,ExceptionCoverage,OutputCoverage,Total_Goals,Covered_Goals,MutationScore"

echo -e "\033[35;10mEvosuite Used Arguments:\nEVOSUITE -class (your class) $ARGS\033[0m"

cd $MYPATH

# parse arguments
# -i clone a repository and analysis it with Evosuite
# -c choose an exist repository to analysis with Evosuite
# -v print version of the script
while getopts ivch arg
do
    case $arg in
        i)
        echo -e "\033[32;10m --------Please input https for git clone:--------- \033[0m"
        read https
        echo "git clone $https"|sh
        target=$https:r:t
        ;;

        c)
        files=$(echo "ls"|sh)
        echo -e "\033[32;10m --------Please Choose Your Target Filename Without '/' In The End:--------\n$files\033[0m"
        read target
        ;;

        v)
        echo version: 1.1
        return 1
        ;;

        h)
        echo "\033[35;10m
        -i clone a repository and analysis it with Evosuite
        -c choose an exist repository to analysis with Evosuite
        -v print version of the script
        -h print this message
        \033[0m"
        return 1

        (?)
        echo error
        return 1
        ;;
    esac
done


cd "$MYPATH/$target" || {
  echo "no such directory!"
  exit
}

echo "current path:" 
echo "pwd"|sh

echo "mvn compile"|sh
echo "mvn dependency:copy-dependencies -DincludeScope=runtime"|sh

# TODO: change to sh
#
fun () {
  echo "$EVOSUITE -setup **/target/classes"|sh
  echo "$EVOSUITE -listClasses -prefix $1 > classList.txt"|sh
  echo "$EVOSUITE -setup **/target/classes **/target/dependency/*"|sh

  classList=(${(f)"$(<classList.txt)"})
  classNum=$#classList
  timePredict=$(echo "scale=1;($classNum * 1.6)"|bc)
  echo -e "\033[32;10m ======================= prefix $1: [ $classNum ] classes, expected to take [ $timePredict ] minutes  ======================== \033[0m"

  analyzed=0
  left=$classNum

  for line in $(cat "$MYPATH/$target/classList.txt")
  do
    echo "$EVOSUITE -class $line $ARGS"|sh
    analyzed=$((analyzed+1))
    left=$((left-1))
    echo -e "\033[32;10m ======================= analyzed [ $analyzed ] classes, [ $left ] left  ======================== \033[0m"
  done
}

list1=($(print -l ./**/target/classes/*(/F)))
# echo -e "\033[31;40m $list1 \033[0m"
list2=(${list1:t})
# echo -e "\033[31;40m $list2 \033[0m"
runlist=(${(u)list2})
# echo -e "\033[31;40m $runlist \033[0m"

for i ($runlist) {
  fun $i
}

echo "rm classList.txt"|sh

#cd ..
