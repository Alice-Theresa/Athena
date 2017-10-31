# 请问您今天要来点FFmpeg命令吗？ 

安装FFmpeg
```
brew install ffmpeg
```

查看FFmpeg
```
brew info ffmpeg
```

重新安装FFmpeg 并装上x265
```
brew reinstall ffmpeg --with-libx265
```

将文件的视频部分用HEVC重编码并去除音轨
```
ffmpeg -i suzumiya.mp4 -vcodec libx265 -an output.mp4
```

将文件音轨分离出来
```
ffmpeg -i suzumiya.mp4 -c:a copy -vn output.mp4
```

#### 参数选项

设置视频编码器  
-c:v  
-codec:v  
-vcodec  

设置音频编码器  
-c:a  
-codec:a  
-acodec  

-i 输入文件  
-vn 关闭视频输出  
-an 关闭音频输出

更多选项可以在FFmpeg官方文档查询
