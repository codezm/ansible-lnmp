#!/bin/bash
declare -r CURRENT_DIR=$(dirname "$0")
# @Reference https://aria2.github.io/manual/en/html/aria2c.html#options https://aria2.github.io/manual/en/html/aria2c.html#input-file
declare -r DOWNLOAD_COMMAND_ARIA2="aria2c -c -x16 -s20 -j20 --no-conf --max-tries=10 --file-allocation=none --input-file=-"
#declare -r DOWNLOAD_COMMAND_ARIA2="aria2c -c --quiet -x16 -s20 -j20 --max-tries=10 --file-allocation=none --input-file=-"
declare -r DOWNLOAD_COMMAND_WGET="wget --show-progress --no-check-certificate -c"
#declare -r DOWNLOAD_COMMAND_WGET="wget --quiet --no-check-certificate -c"

declare ROLES_DIR=$(dirname "$CURRENT_DIR")"/roles/"
#declare DOWNLOAD_COMMAND=""
declare DOWNLOAD_URLS=()
# operate: delete
declare operate=""

# @Reference https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
      if(length($2)== 0){  vname[indent]= ++idx[indent] };
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) { vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, vname[indent], $3);
      }
   }'
}

function init() {
    ROLES_DIR=`echo $(cd "$ROLES_DIR";pwd)`
}

function checkCommand() {
    local ret=0
    # @Reference https://blog.csdn.net/butterfly5211314/article/details/84766207
    command -v $1 > /dev/null 2>&1 || { local ret=1; }

    echo $ret
}

function download_nginx() {
    eval $(parse_yaml "$ROLES_DIR/codezm.nginx/vars/main.yml" "conf_")

    local NGINX_DIR="$ROLES_DIR/codezm.nginx/files"
    #local NGINX_DIR="$ROLES_DIR/../"

    if [ ! -f "$NGINX_DIR/nginx-$conf__nginx_version.tar.gz" ] || [ -f "$NGINX_DIR/nginx-$conf__nginx_version.tar.gz.aria2" ]; then
        DOWNLOAD_URLS+=("${conf__nginx_download_url//{{ _nginx_version \}\}/$conf__nginx_version}\$SAVE_DIR$NGINX_DIR")
        #$DOWNLOAD_COMMAND "$ROLES_DIR/nginx/files" ${conf__nginx_download_url//{{ _nginx_version \}\}/$conf__nginx_version}
    else
        if [[ "$operate" == "delete" ]]; then
            echo "delete: $NGINX_DIR/nginx-$conf__nginx_version.tar.gz"
            rm -f "$NGINX_DIR/nginx-$conf__nginx_version.tar.gz"
        else
            echo "The nginx package is downloaded!"
        fi
    fi
}

function download_php() {
    eval $(parse_yaml "$ROLES_DIR/codezm.php/vars/main.yml" "conf_")

    local PHP_DIR="$ROLES_DIR/codezm.php/files"
    #local PHP_DIR="$ROLES_DIR/../"

    if [ ! -f "$PHP_DIR/php-$conf__php_version.tar.gz" ] || [ -f "$PHP_DIR/php-$conf__php_version.tar.gz.aria2" ]; then
        DOWNLOAD_URLS+=("${conf__php_download_url//{{ _php_version \}\}/$conf__php_version}\$SAVE_DIR$PHP_DIR")
        #$DOWNLOAD_COMMAND $PHP_DIR ${conf__php_download_url//{{ _php_version \}\}/$conf__php_version}
    else
        if [[ "$operate" == "delete" ]]; then
            echo "delete: $PHP_DIR/php-$conf__php_version.tar.gz"
            rm -f "$PHP_DIR/php-$conf__php_version.tar.gz"
        else
            echo "The php package is downloaded!"
        fi
    fi

    php_extensions_list=(`echo ${!conf__php_extensions_list*}`)

    # @Reference https://segmentfault.com/a/1190000008053195
    for i in "${!php_extensions_list[@]}"; do
        if [[ ${php_extensions_list[$i]} =~ "version" ]]; then
            php_extension_version=${!php_extensions_list[$i]}

            # @Reference https://blog.csdn.net/qq_23091073/article/details/83066518
            php_extension_name=${php_extensions_list[$i]##*conf__php_extensions_list_}
            php_extension_name=${php_extension_name%*_version}
            #php_extension_name=${php_extensions_list[$i]/conf__php_extensions_list_/}
            #php_extension_name=${php_extension_name/_version/}

            # debug
            #echo $i ": " ${php_extensions_list[$i]} " - " $php_extension_name":"$php_extension_version
            if [ ! -f "$PHP_DIR/$php_extension_name-$php_extension_version.tgz" ] || [ -f "$PHP_DIR/$php_extension_name-$php_extension_version.tgz.aria2" ]; then
                DOWNLOAD_URLS+=("https://pecl.php.net/get/${php_extension_name}-${php_extension_version}.tgz\$SAVE_DIR$PHP_DIR")
                #$DOWNLOAD_COMMAND $PHP_DIR "https://pecl.php.net/get/${php_extension_name}-${php_extension_version}.tgz"
            else
                if [[ "$operate" == "delete" ]];then
                    echo "delete: $PHP_DIR/$php_extension_name-$php_extension_version.tgz"
                    rm -f "$PHP_DIR/$php_extension_name-$php_extension_version.tgz"
                else
                    echo "The php extension ${php_extension_name}-${php_extension_version} package is downloaded!"
                fi
            fi
        fi
    done
}

function download_mysql() {
    eval $(parse_yaml "$ROLES_DIR/codezm.mysql/vars/main.yml" "conf_")

    local MYSQL_DIR="$ROLES_DIR/codezm.mysql/files"

    mysql_download_lists=(`echo ${!conf__mysql_download_lists*}`)
    # @Reference https://segmentfault.com/a/1190000008053195
    for i in "${!mysql_download_lists[@]}"; do
        mysql_package_name=${!mysql_download_lists[$i]}"-"${conf__mysql_version}

        if [ ! -f "$MYSQL_DIR/$mysql_package_name" ] || [ -f "$MYSQL_DIR/$mysql_package_name.aria2" ]; then
            DOWNLOAD_URLS+=("${conf__mysql_download_url_prefix}${mysql_package_name}\$SAVE_DIR$MYSQL_DIR")
        else
            if [[ "$operate" == "delete" ]]; then
                echo "delete: $MYSQL_DIR/$mysql_package_name"
                rm -f "$MYSQL_DIR/$mysql_package_name"
            else
                echo "The mysql library ${mysql_package_name} package is downloaded!"
            fi
        fi
    done
}

function download_command() {
    if [[ $(checkCommand "aria2c") -eq 0 ]]; then
        DOWNLOAD_COMMAND=$DOWNLOAD_COMMAND_ARIA2
    else
        DOWNLOAD_COMMAND=$DOWNLOAD_COMMAND_WGET
    fi
}

function download_execute() {
    if [[ $(checkCommand "aria2c") -eq 0 ]]; then
        local urls_string=${DOWNLOAD_URLS[*]}
        if [ -n "$urls_string" ]; then
            # @Reference https://www.coder.work/article/2578339
            urls_string=${urls_string//${IFS:0:1}/\\n}
            urls_string=${urls_string//\$SAVE_DIR/\\n\\tdir=}

            echo -e $urls_string | $DOWNLOAD_COMMAND_ARIA2
        fi
    else
        for i in "${!DOWNLOAD_URLS[@]}"; do
            local url_string=${DOWNLOAD_URLS[$i]}
            url_string=${url_string//\$SAVE_DIR/ -P }

            $DOWNLOAD_COMMAND_WGET $url_string
        done
    fi
}

init
download_nginx
download_php
download_mysql
download_execute
