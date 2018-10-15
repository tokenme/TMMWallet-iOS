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

if [ -z $TAC_SCRIPTS_BASE_PATH ]; then
  TAC_SCRIPTS_BASE_PATH=${SRCROOT}
fi

cd "$TAC_SCRIPTS_BASE_PATH"
PRE_IFS=$IFS
IFS=$'\n'
# 查找所有的公共类库中 run.after.sh文件
searchFiles "$TAC_SCRIPTS_BASE_PATH" "tac.run.before.sh"

echo "查找执行脚本的根目录： $TAC_SCRIPTS_BASE_PATH"
if [ ${#SEARCH_FIELS[@]} == 0 ]; then
  echo "没有找到任何需要在构建之前执行的脚本"
else
  echo "找到脚本 ${#SEARCH_FIELS[@]} ${SEARCH_FIELS[@]}"

  for before in ${SEARCH_FIELS[@]}
  do
      echo "执行脚本 $before"
      source $before
  done
fi

PRE_IFS=$IFS
