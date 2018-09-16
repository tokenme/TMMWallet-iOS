PLIST_UTILITIS_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${PLIST_UTILITIS_DIR}/paths.sh"


ensurePlistCheckSchemeArrayExist() {
  if cat $PROJECT_INFO_PLIST| grep -q "LSApplicationQueriesSchemes"
    then
  echo "exist LSApplicationQueriesSchemes"
  else
    $PLISTBUDDY -c "add :LSApplicationQueriesSchemes array" $PROJECT_INFO_PLIST
  fi
}

addSchemeType() {
  schame=$1

  if cat $PROJECT_INFO_PLIST | grep -q "CFBundleURLTypes"
    then
  echo "exist CFBundleURLTypes"
  else
    $PLISTBUDDY -c "add :CFBundleURLTypes array" $PROJECT_INFO_PLIST
  fi

  if cat $PROJECT_INFO_PLIST | grep -q "${schame}"
  then
    echo "url schme exist found"
  else
    echo "CallBack Schame Injection $schame"
    $PLISTBUDDY -c "add :CFBundleURLTypes:0 dict" -c "add :CFBundleURLTypes:0:CFBundleTypeRole string 'Editor'" -c "add :CFBundleURLTypes:0:CFBundleURLName string '${schame}'" -c "add :CFBundleURLTypes:0:CFBundleURLSchemes array" -c "add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string ${schame}"  $PROJECT_INFO_PLIST
  fi
}

addQueryScheme() {
  schame=$1
  count=`$PLISTBUDDY -c "print LSApplicationQueriesSchemes" $PROJECT_INFO_PLIST |wc -l`
  let valueCount=0
  QueryExist=false
  if [ $count -gt 0 ];then
    QueryExist=true
    valueCount=$[$count-3]
  fi

  if [ $QueryExist = false ];then
    $PLISTBUDDY -c "add :LSApplicationQueriesSchemes array" $PROJECT_INFO_PLIST
    count=0
    valueCount=-1
  else
    echo "exist"
  fi

  FOUND_QUERY_SCHEME=false
  if [ $valueCount -ge 0 ]; then
    for index in `seq 0 $valueCount`
    do
      val=`/usr/libexec/PlistBuddy -c "print LSApplicationQueriesSchemes:${index}" $PROJECT_INFO_PLIST`
      if [ "$val" = "$schame" ]; then
        FOUND_QUERY_SCHEME=true
      fi
    done
  fi

  if [ $FOUND_QUERY_SCHEME = false ];then
    $PLISTBUDDY  -c "add :LSApplicationQueriesSchemes:0 string ${schame}"  $PROJECT_INFO_PLIST
  fi
}

addSchemeCallAndResponse() {
  aim=$1
  callback=$2

  addQueryScheme $aim
  addSchemeType $callback
}
