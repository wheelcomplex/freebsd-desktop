#!/bin/bash
if [ `id -u` -ne 0 ]
then
    sudo $0 $@
    exit $?
fi
act="$1"
if [ "$act" != 'install' -a "$act" != 'fetch' ]
then
    pkg $@
    exit $?
fi
shift
target="$@"
echo "fast pkg ${act}ing $target ..."
list=`echo "n" | pkg install xfce xorg 2>&1| grep -A 1000 "to be INSTALLED:"| grep -v "to be INSTALLED:"| grep -v "The process will"|grep -v "to be downloaded."| grep -v "Proceed with this action"| awk -F': ' '{print $1}'`;

maxjobs(){
        local max="$1"
        test -z "$max" && max=5
        if [ $max -eq $max ] 2>/dev/null
        then
            max=$max
        else
            max=5
        fi
        echo "max jobs $max ..."
        while [ : ]
        do
            if [ `jobs 2>&1 | grep -ic 'running'` -le $max ]
            then
                return 0
            fi
            sleep 1
        done
}

for onepkg in $list
do 
    maxjobs 8;echo $onepkg;
    pkg fetch -y $onepkg & 
done
maxjobs 0
if [ "$act" = 'fetch' ]
then
    echo ""
    exit 0
fi
pkg install -y $target
exit $?
#
