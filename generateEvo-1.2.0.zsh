#!/bin/zsh
#
# version 1.2.0
# use -target path to generate Evosuite

setopt EXTENDED_GLOB

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


cd $MYPATH

# parse arguments
# -i clone a repository and analysis it with Evosuite
# -c choose an exist repository to analysis with Evosuite
# -v print version of the script
while {getopts favh arg} {
    case $arg {
        (f)
        echo  "\033[32;10m --------Please input https for git clone:--------- \033[0m"
        read https
        echo "git clone $https"|zsh
        target=$https:r:t
        ;;

        (a)
        files=$(echo "ls"|zsh)
        echo  "\033[32;10m --------Please Choose Your Target Filename Without '/' In The End:--------\n$files\033[0m"
        read target
        ;;

        (v)
        echo version: 1.2
        return 0
        ;;

        (h)
        echo "\033[35;10m
        -f clone a repository and analyze it with Evosuite
        -a choose an exist repository to analyze with Evosuite
        -v print version of the script
        -h print this message
        \033[0m"
        return 0
        ;;

        (?)
        echo error
        return 1
        ;;
      }
  }

echo  "\033[35;10mEvosuite Used Arguments:\nEVOSUITE -class (your class) $ARGS\033[0m"

{cd "$MYPATH/$target"} || {
  echo "no such directory!"
  exit
}

echo "current path:" 
echo "pwd"|zsh

echo "mvn compile"|zsh
echo "mvn dependency:copy-dependencies -DincludeScope=runtime"|zsh

fun () {
  # echo "$EVOSUITE -setup **/target/classes"|zsh
  # echo "$EVOSUITE -listClasses -prefix $1 > classList.txt"|zsh
  echo "$EVOSUITE -setup **/target/classes **/target/dependency/*"|zsh

  # classList=(${(f)"$(<classList.txt)"})

  print -l **/target/classes > classFiles.txt

  classFiles=(${(f)"$(<classFiles.txt)"})

  for line ($classFiles) {
    echo  "\033[32;10m ======================= target path: [ $line ] ======================== \033[0m"

    echo "$EVOSUITE -listClasses -target $line > classList.txt"|zsh
    classList=(${(f)"$(<classList.txt)"})
    classNum=$#classList
    timePredict=$(echo "scale=1;($classNum * 1.2)"|bc)
    repeat 3 {
    echo  "\033[32;10m ======================= total [ $classNum ] classes in path, expected to take [ $timePredict ] minutes  ====================== \033[0m"
    }

    echo "$EVOSUITE -target $line $ARGS"|zsh
  }
}

# list1=($(print -l ./**/target/classes/*(/F)))
# echo  "\033[31;40m $list1 \033[0m"
# list2=(${list1:t})
# echo  "\033[31;40m $list2 \033[0m"
# runlist=(${(u)list2})
# echo  "\033[31;40m $runlist \033[0m"

# for i ($runlist) {
#   fun $i
# }

fun

echo "\033[35;10m====================Finished analysis of target :[ $target ], total calss number [ $classNum ] ==========================\033[0m "

