# 鸿蒙套壳网页 APP（ArkWeb）

基于 **ArkWeb** 制作的鸿蒙套壳网页 APP，支持打包常用网页为原生应用。

---

## 🔗 内置 Demo 链接（`src/main/ets/pages/Index.ets`）

当前已集成 5 个常用网页，默认启用 **飞书**，其余已注释，可自行修改：

```ts
// 飞书（默认启用)
const url = "https://web.feishu.cn";

// 网易云音乐
// const url = "https://music.163.com";

// 哔哩哔哩
// const url = "https://www.bilibili.com";

// DeepSeek
// const url = "https://chat.deepseek.com";

// 阿里巴巴矢量图标库
// const url = "https://www.iconfont.cn";
```

---

## 🛠️ 自定义配置

完成 URL 设定后，需同步修改以下文件，确保图标、名称、包名一致：

| 文件路径 | 作用 |
| --- | --- |
| `src/main/resources/base/media/layered_image.json` | APP 图标 |
| `src/main/resources/base/element/string.json` | 应用名称等资源 |
| `AppScope/app.json5` | 全局配置 |
| `AppScope/resources/base/element/string.json` | 应用名称等资源 |

---

## ✨ 功能特性

| 功能 | 说明 |
| --- | --- |
| 🌗 深色 / 浅色模式 | 根据系统主题自动切换 |
| 📏 标题栏高度调节 | 默认隐藏系统标题栏，可自定义高度 |
| 📱 多设备适配 | 支持鸿蒙 Next PC、手机、平板 |
| ⬅️ 标题栏操作 | 返回、刷新按钮 |
| 🖱️ 右键菜单 | 支持复制、粘贴、复制图片、复制链接等 |
| ⬇️ 单线程下载 | 监听下载事件并打开下载窗口 |
| 🍪 Cookie 管理 | 自动保存 |

---

## 📸 效果图

<img width="2096" height="1396" alt="image" src="https://github.com/user-attachments/assets/4b2e30e6-dd89-4175-bdf8-75647abdd4ad" />
<img width="2096" height="1402" alt="image" src="https://github.com/user-attachments/assets/b0d562e2-ee3b-4165-87ce-210e88f029d2" />
<img width="2094" height="1398" alt="image" src="https://github.com/user-attachments/assets/e9b24b17-46e2-4d63-8961-b9a17066dab2" />
<img width="2092" height="1406" alt="image" src="https://github.com/user-attachments/assets/71a63d76-02f5-4735-8c83-a4882cdb15ac" />
<img width="2094" height="1394" alt="image" src="https://github.com/user-attachments/assets/20b810df-ff1b-4616-b91c-3c09d593d7a6" />

> 如有更多需求，欢迎提 Issue 或 Pull Request！

