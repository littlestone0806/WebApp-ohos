import { webview } from '@kit.ArkWeb';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { DownloadConfirmDialog } from '../component/DownloadConfirmDialog'
import { IAbstractDownloadHandler } from '../delegate/IWebDownloadFile'
import { WebDownloadFileHelper } from '../delegate/WebDownloadFileImpl'
import { EmitterUtil } from '../utiles/EmitterUtil'

const url = "https://web.feishu.cn"; //飞书
//const url = "https://music.163.com";  //网易云音乐
//const url = "https://www.bilibili.com";  //B站
//const url = "https://chat.deepseek.com";  //deepseek
//const url = "https://www.iconfont.cn";  //阿里巴巴矢量图库

const setPCUserAgent = false;  //是否强制使用PC的UA,false为自适应UA
const titleBlankHeight = 40;  //空白标题栏的高度，如果你的网页最上面一排没有按钮和需要点击的内容，可以设置为0

// 定义菜单类型枚举
enum MenuType {
  IMAGE = "IMAGE",
  LINK = "LINK",
  EDITABLE = "EDITABLE",
  SELECTION = "SELECTION"
}

//申请全局剪切板权限
const permissions: Array<Permissions> = ['ohos.permission.READ_PASTEBOARD'];
// 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
function reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
      } else {
        // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
        return;
      }
    }
    // 授权成功
  }).catch((err: BusinessError) => {
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}

@Entry
@Component
struct WebComponent {
  needReloadWhenVisible: boolean = false ;  // Web组件不可见时render退出后阻止重新加载页面，在可见时重新加载页面。
  webIsVisible: boolean = false;            // 判断Web组件是否可见。

  // 此处是将子进程异常崩溃和其它异常原因做了区分，应用开发者可根据实际业务特点，细化对应异常的处理策略。
  renderReloadMaxForCrashed: number = 5;    // 设置因为异常崩溃后重新加载的最大重试次数，应用可根据业务特点，自行设置试错上限。
  renderReloadCountForCrashed: number = 0;  // 异常崩溃后重新加载的次数。
  renderReloadMaxForOthers: number = 10;    // 设置因为其它异常原因退出的最大重试次数，应用可根据业务特点，自行设置试错上限。
  renderReloadCountForOthers: number = 0;   // 其它异常原因退出后重新加载的次数。

  // 创建Web组件。
  controller: webview.WebviewController = new webview.WebviewController();
  @State webDownloadFile: IAbstractDownloadHandler = new WebDownloadFileHelper()
  downloadWebLoading: CustomDialogController = new CustomDialogController({
    //Web页面加载的弹窗控制器
    builder: DownloadConfirmDialog(),
    customStyle: true,
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    isModal: false,
    openAnimation: {
      duration: 1200,
      curve: Curve.Friction,
      delay: 500,
      playMode: PlayMode.Alternate,
    }
  })

  private result: WebContextMenuResult | undefined = undefined;
  @State linkUrl: string = '';
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State window_width: number = 0;
  @State window_height: number = 0;
  @State menu_height: number = 0;
  @State showMenu: boolean = false;
  @State currentMenuType: MenuType = MenuType.IMAGE; // 当前菜单类型
  uiContext: UIContext = this.getUIContext();

  // 图片菜单构建器
  @Builder
  ImageMenuBuilder() {
    Menu() {
      MenuItem({ content: '复制图片' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.copyImage();
          this.showMenu = false;
        })
    }
    .width(100)
    .height(50)
  }
  // 链接菜单构建器
  @Builder
  LinkMenuBuilder() {
    Menu() {
      MenuItem({ content: '复制链接' })
        .width(100)
        .height(50)
        .onClick(() => {
          let pasteData = pasteboard.createData('text/plain', this.linkUrl);
          pasteboard.getSystemPasteboard().setData(pasteData, (error) => {
            if (error) {
              return;
            }
          })
          this.showMenu = false;
        })
    }
    .width(100)
    .height(50)
  }
  // 可编辑区域菜单构建器
  @Builder
  EditableMenuBuilder() {
    Menu() {
      MenuItem({ content: '剪切' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.cut();
          this.showMenu = false;
        })
      MenuItem({ content: '复制' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.copy();
          this.showMenu = false;
        })
      MenuItem({ content: '粘贴' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.paste();
          this.showMenu = false;
        })
      MenuItem({ content: '全选' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.selectAll();
          this.showMenu = false;
        })
    }
    .width(100)
    .height(200)
  }
  // 选中文本菜单构建器
  @Builder
  SelectionMenuBuilder() {
    Menu() {
      MenuItem({ content: '复制' })
        .width(100)
        .height(50)
        .onClick(() => {
          this.result?.copy();
          this.showMenu = false;
        })
    }
    .width(100)
    .height(50)
  }

  // 动态菜单构建器（根据类型选择）
  @Builder
  MenuBuilder() {
    if (this.currentMenuType === MenuType.IMAGE) {
      this.ImageMenuBuilder();
    } else if (this.currentMenuType === MenuType.LINK) {
      this.LinkMenuBuilder();
    } else if (this.currentMenuType === MenuType.EDITABLE) {
      this.EditableMenuBuilder();
    } else if (this.currentMenuType === MenuType.SELECTION) {
      this.SelectionMenuBuilder();
    }
  }
  onBackPress() {
    // 当前页面是否可前进或者后退给定的step步(-1),正数代表前进，负数代表后退
    if (this.controller.accessStep(-1)) {
      this.controller.backward(); // 返回上一个web页
      // 执行用户自定义返回逻辑
      return true
    } else {
      // 执行系统默认返回逻辑，返回上一个page页
      return false
    }
  }
  aboutToAppear(): void {
    //第一次启动设置一下cookie，默认为30s存储一次
    webview.WebCookieManager.configCookieSync(url, 'a=b', false, false);
    // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    reqPermissionsFromUser(permissions, context);
    //定义下载监听事件
    EmitterUtil.on<number>('affffa', (event) => {
      if (event?.data === 1) {
        this.downloadWebLoading.open()
      } else {
        this.downloadWebLoading.close()
      }
    })
  }
  aboutToDisappear(): void {
    //关闭下载监听事件
    EmitterUtil.off<number>('affffa', (event) => {
    })
    //立刻将cookie写入磁盘，防止登录完成30s内关闭app，登录信息丢失
    webview.WebCookieManager.saveCookieAsync((error) => {
      if (error) {
        console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
      }
    })
  }

  //功能：创建一个悬浮的空白区，用于实现无标题栏沉浸模式下的拖拽操作
  @Builder
  OverlayNode() {
    Column() {
      Row(){
        //在空白区增加一个返回按钮
        Image($r('sys.media.ohos_ic_compnent_titlebar_back'))
          .size({ width: 23, height: 23 })
          .margin({ left: 10,  top: 10})
          .hoverEffect(HoverEffect.Highlight)
          .borderRadius(10)
          .fillColor(!Color.Transparent)
          .onClick(() => {
            this.controller.backward(); // 返回上一个web页
          })
        Image($r('app.media.refresh'))
          .size({ width: 23, height: 23 })
          .margin({ left: 5,  top: 10})
          .hoverEffect(HoverEffect.Highlight)
          .borderRadius(10)
          .fillColor(!Color.Transparent)
          .onClick(() => {
            this.controller.refresh(); // 刷新web页面
          })
      }
      Blank()
        .color(Color.Transparent)
    }
    .alignItems(HorizontalAlign.Start)  // 水平方向靠左
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        try {
          let wnd: window.Window = this.windowStage.getMainWindowSync();
          if (canIUse("SystemCapability.Window.SessionManager")) {
            wnd.startMoving().then(() => {
              console.info('wnd Succeeded in starting moving window');
            }).catch((err: BusinessError) => {
              console.error(`Failed to start moving. Cause code: ${err.code}, message: ${err.message}`);
            });
          }
        } catch (exception) {
          console.error(`Failed to start moving. Cause code: ${exception.code}, message: ${exception.message}`);
        }
      }
    })
    .width('100%')
    .height(40)
  }
  // get the window manager from AppStorage
  private windowStage = AppStorage.get('window') as window.WindowStage;
  build() {
    Column() {
      //如果你的网页最上面一排没有按钮和需要点击的内容，可以注释掉Blank以达到最佳显示效果
      Blank()
        .height(titleBlankHeight)
        .color(Color.Transparent)
      Web({ src: url, controller: this.controller })
        .layoutWeight(1) //设置layoutWeight属性优先保证web控件的大小，不至于被Blank给挤出去造成下方显示不全
        .hitTestBehavior(HitTestMode.Transparent)
        //当组件大小改变时，获取窗体大小，用于给右键菜单定位
        .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
          window.getLastWindow(this.uiContext.getHostContext()).then((data) => {
            const properties = data?.getWindowProperties();
            this.window_width = properties.windowRect.width;
            this.window_height = properties.windowRect.height - titleBlankHeight;
          });
        })
        // 触发右键菜单
        .onContextMenuShow((event) => {
          if (event) {
            this.result = event.result;
            this.linkUrl = event.param.getLinkUrl();
            //当为不可编辑内容时
            if(event.param.isEditable() == false){
              //当为图片资源时
              if(event.param.getMediaType() === 1) {
                this.currentMenuType = MenuType.IMAGE;
                this.menu_height = 50;
              }
              else{
                //当选中了不可编辑的文字时
                if(event.param.getSelectionText() != ""){
                  this.currentMenuType = MenuType.SELECTION;
                  this.menu_height = 50;
                }
                else{
                  //当点击目标是链接时
                  if(event.param.getUnfilteredLinkUrl() != ""){
                    this.currentMenuType = MenuType.LINK;
                    this.menu_height = 50;
                  }
                  else{
                    return false;
                  }
                }
              }
            }
            //当为可编辑内容时
            else{
              this.currentMenuType = MenuType.EDITABLE;
              this.menu_height = 200;
            }
          }
          // 获取鼠标位置并转换为vp单位
          this.offsetX = this.uiContext.px2vp(event.param.x() - this.window_width / 2) + 50;
          this.offsetY = this.uiContext.px2vp(event.param.y() - this.window_height / 2) + this.menu_height/2;
          this.showMenu = true;
          return true;
        })
        .bindPopup(this.showMenu,
          {
            builder: this.MenuBuilder(),
            enableArrow: false,
            placement: Placement.RightBottom,
            offset: { x: this.offsetX, y: this.offsetY },
            mask: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.showMenu = false;
                this.result!.closeContextMenu();
              }
            }
          })
        .onControllerAttached(() => {
          //设置web的UA
          if(setPCUserAgent)this.controller.setCustomUserAgent("Mozilla/5.0 (PC; Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 htbrowser")
          this.webDownloadFile.setDownloadDelegate(this.controller)
        })
      .backgroundColor(Color.Transparent) //设置浏览器加载时的背景色
      .darkMode(WebDarkMode.Auto)  //设置深色模式为自动
      .domStorageAccess(true)
      .onlineImageAccess(true)
      .imageAccess(true)
      .fileAccess(true)
      .javaScriptAccess(true)
      .databaseAccess(true)
      .copyOptions(CopyOptions.LocalDevice)
      .mixedMode(MixedMode.All)
      .horizontalScrollBarAccess(false) //隐藏横向滚动条
      .verticalScrollBarAccess(false)  //隐藏纵向滚动条
      .onVisibleAreaChange([0, 1.0], (isVisible) => {
        this.webIsVisible = isVisible;
        if (isVisible && this.needReloadWhenVisible) { // Web组件可见时重新加载页面。
          this.needReloadWhenVisible = false;
          this.controller.loadUrl(url);
        }
      })
      // 应用监听渲染子进程异常退出回调，并进行异常处理。
      .onRenderExited((event) => {
        if (!event) {
          return;
        }
        if (event.renderExitReason == RenderExitReason.ProcessCrashed) {
          if (this.renderReloadCountForCrashed >= this.renderReloadMaxForCrashed) {
            // 设置重试次数上限保护，避免必现问题导致页面被循环加载。
            return;
          }
          console.log('renderReloadCountForCrashed: ' + this.renderReloadCountForCrashed);
          this.renderReloadCountForCrashed++;
        } else {
          if (this.renderReloadCountForOthers >= this.renderReloadMaxForOthers) {
            // 设置重试次数上限保护, 避免必现问题导致页面被循环加载。
            return;
          }
          console.log('renderReloadCountForOthers: ' + this.renderReloadCountForOthers);
          this.renderReloadCountForOthers++;
        }
        if (this.webIsVisible) {
          // Web组件可见则立即重新加载。
          this.controller.loadUrl(url);
          return;
        }
        // Web组件不可见时不立即重新加载。
        this.needReloadWhenVisible = true;
      })
      .onErrorReceive((event) => {
        console.error('onErrorReceive event:', JSON.stringify(event));
      })
    }
    .width('100%')
    .height('100%')
    .overlay(this.OverlayNode(), { align: Alignment.Top })
  }
}