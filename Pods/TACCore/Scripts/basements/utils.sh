# 入参 path 要查找的路径, pattern 模式
SEARCH_FIELS=()
searchFiles() {
  PRE_IFS=$IFS
  IFS=$'\n'
  path=$1
  pattern=$2
    echo "before find"
    echo "path is $path"
  SEARCH_FIELS=`find "$path" -name "${pattern}" -maxdepth 100`
  IFS=$PRE_IFS
}

function step(){
    echo -e "\033[32m[ $1 ]\033[0m"
}

## Error to warning with blink
function ERROR(){
    echo -e "\033[31m\033[01m\033[05m[ $1 ]\033[0m"
    exit 1
}
