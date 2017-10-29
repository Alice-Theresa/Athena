# Re:从零开始的FFmpeg编译

将fdk-aac、x264与FFmpeg一起编译到iOS平台上

## 准备
##### 下载gas-preprocessor

https://github.com/libav/gas-preprocessor

将 gas-preprocessor.pl 复制到 /usr/local/bin/ 目录下

并在终端输入
```
chmod 777 /usr/local/bin/gas-preprocessor.pl
```

##### 安装yasm

```
brew install yasm
```

## 编译fdk-aac

##### 安装automake libtool

```
brew install automake libtool
```

##### 下载fdk-aac编译脚本
https://github.com/kewlbear/fdk-aac-build-script-for-iOS

##### 下载fdk-aac
https://github.com/mstorsjo/fdk-aac

下载后重命名文件夹为fdk-aac-0.1.5，并将文件夹放入编译脚本目录下

##### 编译

进入fdk-aac-0.1.5文件夹并执行

```
./autogen.sh
```

返回上一层,执行
```
./build-fdk-aac.sh 
```
完成后再执行

```
./build-fdk-aac.sh lipo
```

将会生成fdk-aac-ios文件夹

## 编译x264

##### 下载x264编译脚本
https://github.com/depthlove/x264-iOS-build-script

##### 编译

执行
```
./build-x264.sh
```

将会自动下载x264文件并编译

完成后执行
```
./build-x264.sh lipo
```

将会生成x264-iOS文件夹，将其重命名为fat-x264

## 编译ffmpeg

##### 下载ffmpeg编译脚本
```
https://github.com/kewlbear/FFmpeg-iOS-build-script
```

将刚才编译生成的两个文件夹放入脚本目录下

##### 修改build-ffmpeg.sh

1. 将
```
#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios
```
改为
```
FDK_AAC=`pwd`/fdk-aac-ios
```

2. 将
```
#X264=`pwd`/fat-x264
```
改为
```
X264=`pwd`/fat-x264
```

3. 将
```
if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi
if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac"
fi
```
改为
```
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264 --enable-nonfree --enable-libfdk-aac"
```

4. 将
```
CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
```
改为
```
CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET"
```

##### 编译

执行
```
./build-ffmpeg.sh
```

完成后执行
```
./build-ffmpeg.sh lipo
```

将会生成FFmpeg-iOS文件夹

## 整合

将FFmpeg-iOS、fdk-aac-ios、fat-x264导入项目中
添加后需要以下设置
1. 在Build Setting的Header Search Paths里添加路径
```
$(SRCROOT)/FFmpeg-iOS/include
```

2. Enable Bitcode设为NO

3. Linked Frameworks and Libraries中添加
```
CoreMedia framework
VideoToolbox framework
AudioToolbox framework
libz.1.2.11.tbd
libbz2.1.0.tbd
libiconv.2.4.0.tbd
```
