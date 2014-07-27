Warden 守望者大战
=========

###如何在自己的DOTA2里面载入这个模式：

1. 在本页面的右侧点击 Download Zip
2. 将下载的Zip文件解压缩后改名为 Warden（从`Warden - master` 改为 `Warden`）
3. 将Warden文件夹复制到自己的 `dota 2 beta/dota/addons`文件夹
4. 打开`dota 2 beta/dota/addonlist.txt`（如果没有就新建一个）
5. 将`addonlist.txt`里面的内容改为
```
"AddonList"
{
	"Warden"		"1"
}
```
6. 将`dota 2 beta/dota/addons/Warden/w.cfg`复制到`dota 2 beta/dota/cfg/w.cfg`（一定要有这个文件，否则就是你的Warden文件夹没有复制对地方）
7. 带控制台启动游戏（启动选项加入`-console`），在控制台输入 `exec w`
8. 如果你在控制台看到 `[WARDEN] Hello World!` 那么就是载入正确了。