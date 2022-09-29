#!/bin/bash

if [ -z ${PETALINUX+x} ]
then
   echo 'could not find Petalinux path $PETALINUX'
   echo 'did you source Petalinux settings.sh ?'
   exit 1
fi

petalinux-create --type project --template zynqMP --name $project_name
cd $project_name
petalinux-config --get-hw-description=./../hardware --silentconfig
petalinux-create -t apps --template c --name pgmpa
cp -rf ../scripts/petalinux/project-spec/ ./
echo CONFIG_pgmpa=y >> project-spec/configs/rootfs_config
sed -i 's:# CONFIG_imagefeature-debug-tweaks is not set:CONFIG_imagefeature-debug-tweaks=y:g' project-spec/configs/rootfs_config
sed -i 's:# CONFIG_auto-login is not set:CONFIG_auto-login=y:g' project-spec/configs/rootfs_config
sed -i 's:# CONFIG_gdb is not set:CONFIG_gdb=y:g' project-spec/configs/rootfs_config
sed -i 's:# CONFIG_gdbserver is not set:CONFIG_gdbserver=y:g' project-spec/configs/rootfs_config
echo "RM_WORK_EXCLUDE += \"pgmpa\""  >> project-spec/meta-user/conf/petalinuxbsp.conf
petalinux-build

