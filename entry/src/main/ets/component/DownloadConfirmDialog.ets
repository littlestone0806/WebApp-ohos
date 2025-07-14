import { EventIdConstants } from '../contants/EventIdConstants'
import { WebDownloadFileHelper } from '../delegate/WebDownloadFileImpl'
import { EmitterUtil } from '../utiles/EmitterUtil'

// 添加阴影配置
const shadowOptions: ShadowOptions = {
  radius: 16,
  color: $r('app.color.shadow'),
  offsetX: 0,
  offsetY: 4
};

@CustomDialog
export struct DownloadConfirmDialog {
  @State isDownloading: boolean = false
  @State downloadProgress: number = 0
  dialogController: CustomDialogController

  aboutToAppear(): void {
    EmitterUtil.on<number>(EventIdConstants.DOWNLOAD_PROGRESS_EVENT_ID, (event) => {
      if (!event.data) {
        return
      }
      this.downloadProgress = event.data
    })
  }

  aboutToDisappear(): void {
    EmitterUtil.off<number>(EventIdConstants.DOWNLOAD_PROGRESS_EVENT_ID, (event) => {
      // 注销事件监听
    })
  }

  build() {
    Column() {
      if (this.isDownloading) {
        Column() {
          Text('下载中...')
            .fontSize(16)
            .lineHeight(20)
            .fontColor($r('app.color.progress_text'))
            .margin({ top: 24, bottom: 16 })
          Progress({ value: this.downloadProgress, type: ProgressType.Linear })
            .width('90%')
            .height(20)
          Button("取消")
            .onClick(() => {
              WebDownloadFileHelper.cancelDownload();
              this.dialogController.close();
            })
            .width(148)
            .height(40)
            .backgroundColor($r('app.color.button_cancel_bg'))
            .fontSize(16)
            .fontColor($r('app.color.button_cancel_text'))
            .stateEffect(true)
            .hoverEffect(HoverEffect.Scale)
            .borderRadius(20)
        }
        .width('30%')
        .height(148)
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.dialog_bg'))
        .shadow(shadowOptions)
      } else {
        Column() {
          Text('是否下载该文件？')
            .fontSize(16)
            .lineHeight(20)
            .fontColor($r('app.color.dialog_text'))
            .margin({ bottom: 16 })
          Row() {
            Button("取消")
              .onClick(() => {
                this.dialogController.close();
                WebDownloadFileHelper.cancelDownload();
              })
              .width('40%')
              .height(40)
              .backgroundColor($r('app.color.button_cancel_bg'))
              .fontSize(16)
              .fontColor($r('app.color.button_cancel_text'))
              .stateEffect(true)
              .hoverEffect(HoverEffect.Scale)
              .borderRadius(20)
              .zIndex(0)

            Line()
              .width(1)
              .height(24)
              .backgroundColor($r('app.color.divider'))
              .zIndex(1)

            Button("下载")
              .width('40%')
              .height(40)
              .backgroundColor($r('app.color.button_download_bg'))
              .fontSize(16)
              .fontColor($r('app.color.button_download_text'))
              .stateEffect(true)
              .hoverEffect(HoverEffect.Scale)
              .borderRadius(20)
              .zIndex(0)
              .onClick(async () => {
                this.isDownloading = true
                WebDownloadFileHelper.startDownload()
              })
          }
        }
        .width('30%')
        .height(108)
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.dialog_bg'))
        .shadow(shadowOptions)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}