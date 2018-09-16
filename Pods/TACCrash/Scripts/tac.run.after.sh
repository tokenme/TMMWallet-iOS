CURRENT_FILE_PATH=$(dirname "${BASH_SOURCE[0]}")
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "测试"
if [ $TAC_MODULE_RUN_AFTER_CRASH ]; then
  echo "模块 Crash 中的脚本已经执行过，不再重复执行 ${CURRENT_FILE_PATH}"
else
  echo "执行模块 Crash 中的脚本，脚本路径为 ${CURRENT_FILE_PATH}"
  source $DIR/run
  #endfile and define the env
  TAC_MODULE_RUN_AFTER_CRASH=true
fi
