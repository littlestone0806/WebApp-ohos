用ArkWeb制作的鸿蒙套壳网页APP。

目前demo里面放了五个APP链接，分别如下。可在src/main/ets/pages/Index.ets文件中自行设置。也可以设定自己的链接

const url = "https://web.feishu.cn"; //飞书

//const url = "https://music.163.com";  //网易云音乐

//const url = "https://www.bilibili.com";  //B站

//const url = "https://chat.deepseek.com";  //deepseek

//const url = "https://www.iconfont.cn";  //阿里巴巴矢量图库



设定完成后，记得替换以下几个地方的APP图标、显示名称、包名

src/main/resources/base/media/layered_image.json

src/main/resources/base/element/string.json

AppScope/app.json5

AppScope/resources/base/element/string.json



支持功能：
1、支持深色浅色模式切换

2、支持标题栏高度调节，默认隐藏系统标题栏

3、支持鸿蒙Next PC、手机、平板端部署

4、标题栏支持返回和刷新

5、支持右键菜单，可根据选中的内容，进行复制粘贴、复制图片、复制链接等操作

6、支持单线程下载，可监听下载事件并打开下载窗口

7、支持自动保存cookie


效果图如下
<img width="2096" height="1396" alt="image" src="https://github.com/user-attachments/assets/4b2e30e6-dd89-4175-bdf8-75647abdd4ad" />
<img width="2096" height="1402" alt="image" src="https://github.com/user-attachments/assets/b0d562e2-ee3b-4165-87ce-210e88f029d2" />
<img width="2094" height="1398" alt="image" src="https://github.com/user-attachments/assets/e9b24b17-46e2-4d63-8961-b9a17066dab2" />
<img width="2092" height="1406" alt="image" src="https://github.com/user-attachments/assets/71a63d76-02f5-4735-8c83-a4882cdb15ac" />
<img width="2094" height="1394" alt="image" src="https://github.com/user-attachments/assets/20b810df-ff1b-4616-b91c-3c09d593d7a6" />



