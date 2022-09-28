#!/bin/zsh
#
# use -target path to generate Evosuite
 
version=1.0.3

setopt EXTENDED_GLOB

#---------------------------------------------------------------------------------------
#---------------  Change this area to your local Evosuite path   -----------------------
#---------------------------------------------------------------------------------------
EVOSUITE="java -jar /data/chenyi/projects/evoTest/Evosuite/evosuite-1.2.0.jar"

#---------------------------------------------------------------------------------------
#----------------------- Change path where to store project ----------------------------
#---------------------------------------------------------------------------------------
MYPATH="/data/chenyi/projects/evoTest"

#---------------------------------------------------------------------------------------
#------------------- arguments pass to Evosuite (dont need to change) ------------------
#---------------------------------------------------------------------------------------
ARGS="-Doutput_variables=TARGET_CLASS,criterion,Size,Length,Coverage,BranchCoverage,CBranchCoverage,LineCoverage,MethodCoverage,MethodNoExceptionCoverage,ExceptionCoverage,OutputCoverage,Total_Goals,Covered_Goals,MutationScore"

helpMsg="
-f clone a repository and analyze it with Evosuite
-a choose an exist repository to analyze with Evosuite
-d [target_directory] , analyze all projects in target directory
-p postfix of Evosuite generated filename, default evosuite-report and evosuite-test 
-v print version of the script
-h print this message
"

errorMsg="error!  process stop!"

postfix="1"

# ------------------------------------ functions --------------------------------------------

fun () {
  pwd
  {cd "$1"} || {
    echo "no such directory!"
     exit
  }
  echo "current path:" 
  pwd

  (! mvn compile) && { echo mvn compile $errorMsg; return 1}
  # (! mvn dependency:copy-dependencies -DincludeScope=runtime) && { echo mvn $errorMsg; return 1}
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
  cd ..
}

doAll () {
  cd $1
  print -l *(/F) > DirList.txt
  dirList=(${(f)"$(<DirList.txt)"})
  # rm ./**/evosuite-report/statistics.csv
  for dir ($dirList) {
    echo starting doAll..........
    fun $dir
    cd $1
  }
  
  # 批量重命名生成的csv文件
  # echo "autoload -U zmv"|zsh
  # echo zmv "./(*)/evosuite-report/statistics.csv" './$1/evosuite-report/'"statistics-$postfix.csv"|zsh
  #
  # echo "===================== zipping results ... ================="
  # (! zip results.zip ./**/evosuite-report/statistics-$postfix.csv) && { echo zip $errorMsg; return 1}

  echo "======================= generating results to .tar file ====================="
  (! tar -cvf results-$postfix.tar ./**/evosuite-report-$postfix/statistics.csv) && {echo "tar csv $errorMsg"; return 1}
  (! tar -cfv tests-generate-$postfix.tar ./**/evosuite-test-$postfix/*) && {echo "tar test $errorMsg"; return 1}
  (! rm -rf ./**/evosuite-*-*) && {echo "rm $errorMsg; return 1"}
}


# --------------------------------------- main -------------------------------------------
cd $MYPATH

if [[ $# == 0 ]] {
  echo "Usage: $helpMsg"
  return 1
}

# parse arguments
# -i clone a repository and analysis it with Evosuite
# -c choose an exist repository to analysis with Evosuite
# -v print version of the script
while {getopts d:p:favh arg} {
    case $arg {
        (f)
        echo  "\033[32;10m --------Please input https for git clone:--------- \033[0m"
        read https
        echo "git clone $https"|zsh
        target=$https:r:t
	fun $target
        ;;

        (a)
        files=$(echo "ls"|zsh)
        echo  "\033[32;10m --------Please Choose Your Target Filename Without '/' In The End:--------\n$files\033[0m"
        read target
	fun $target
        ;;

        (v)
        echo version:$version
        return 0
        ;;

        (h)
        echo "\033[35;10mUsage: $helpMsg\033[0m"
        return 0
        ;;

    	(p)
		postfix=$OPTARG
		ARGS="-Doutput_variables=TARGET_CLASS,criterion,Size,Length,Coverage,BranchCoverage,CBranchCoverage,LineCoverage,MethodCoverage,MethodNoExceptionCoverage,ExceptionCoverage,OutputCoverage,Total_Goals,Covered_Goals,MutationScore -Dreport_dir=evosuite-report-$postfix -Dtest_dir=evosuite-test-$postfix"
		;;

        (d)
        # echo $arg option with arg: $OPTARG
		t=`date "+%m-%d-%H-%M-%S"`
		# echo "====================== $t"
		[[ $postfix == 1 ]] && postfix=$t
		ARGS="-Doutput_variables=TARGET_CLASS,criterion,Size,Length,Coverage,BranchCoverage,CBranchCoverage,LineCoverage,MethodCoverage,MethodNoExceptionCoverage,ExceptionCoverage,OutputCoverage,Total_Goals,Covered_Goals,MutationScore -Dreport_dir=evosuite-report-$postfix -Dtest_dir=evosuite-test-$postfix"
        doAll $OPTARG
        return 0
        ;;

        (?)
        echo error
        return 1
        ;;
      }
  }


echo "\033[35;10m====================Finished analysis of target :[ $target ], total calss number [ $classNum ] ==========================\033[0m "

