#!/bin/sh
#
# Copyright 2016 stonedong, Tencent. All rights reserved.
#
# V1.0.0
#
# 2018.01.25
#

# 引用公共库
CRASH_SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${CRASH_SCRIPTS_DIR}/basements/basements.sh"


if [ -z  $TAC_SCRIPTS_BASE_PATH ]; then
  TAC_SCRIPTS_BASE_PATH=${SRCROOT}
fi

echo "执行构建之后需要运行的脚本"
# 查找所有的公共类库中 run.after.sh文件
searchFiles "$TAC_SCRIPTS_BASE_PATH" "tac.run.after.sh"

if [ ${#SEARCH_FIELS[@]} == 0 ]; then
  echo "没有找到任何需要在构建之后执行的脚本"
else
PRE_IFS=$IFS
IFS=$'\n'
  for after in ${SEARCH_FIELS[@]}
  do
      source $after
  done
  IFS=$PRE_IFS
fi
