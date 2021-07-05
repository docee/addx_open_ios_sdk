#!/bin/bash

cd $(dirname $0)

diff=`git diff`


if [ ${#diff} != 0 ];
then
    echo "有修改需要提交,请输入提交的commit信息:"
    git add .
    read commitInfo
    echo "--------commitInfo--------"
    echo "commit信息:\n"$commitInfo""
    echo "--------commitInfo--------"
    git commit -m $commitInfo
fi

echo "--------tag list--------"
echo `git tag -l`
echo "--------tag list--------"

echo "根据上面的tag输入新tag"
read thisTag

# 获取podspec文件名
podSpecName=`ls|grep ".podspec$"|sed "s/\.podspec//g"`
echo $podSpecName

# 修改版本号
sed -i "" "s/s.version *= *[\"\'][^\"]*[\"\']/s.version=\"$thisTag\"/g" $podSpecName.podspec

pod cache clean --all

pod lib lint --allow-warnings --verbose # --use-libraries


# 验证失败退出
if [ $? != 0 ];then
    exit 1
fi


git commit $podSpecName.podspec -m "update podspec"
git push
git tag -m "update podspec" $thisTag
git push --tags

pod repo push '31-moudlesspecs' $podSpecName.podspec --allow-warnings 
