import { promptAction } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { BusinessError } from '@kit.BasicServicesKit'
import { EventIdConstants } from '../contants/EventIdConstants'
import { EmitterUtil } from '../utiles/EmitterUtil'
import { IAbstractDownloadHandler } from './IWebDownloadFile'

/**
 * @dec web下载文件方法实现,
 * @author ZhangHuiXin,
 * @date 2025/3/11 20:26,
 */

export class WebDownloadFileHelper extends IAbstractDownloadHandler {
  private static instance: WebDownloadFileHelper = new WebDownloadFileHelper()
  private static _webDownloadItem: webview.WebDownloadItem | null = null
  private static _downloadProgress: number = 0

  /**
   * 单例访问入口
   * */
  static getInstance(): WebDownloadFileHelper {
    return WebDownloadFileHelper.instance
  }

  /**
   * 静态下载启动方法
   * */
  static startDownload(customPath?: string) {
    if (!WebDownloadFileHelper._webDownloadItem) {
      throw new Error('DOWNLOADER_NOT_INITIALIZED')
    }

    const effectivePath = customPath || WebDownloadFileHelper.generateDefaultPath()
    WebDownloadFileHelper.instance.executeDownload(effectivePath)
  }

  static openDownloadPopUpWindow() {
    EmitterUtil.post<number>('affffa', 1)
  }

  static closeDownloadPopUpWindow() {
    EmitterUtil.post<number>('affffa', 2)
  }

  /**
   * 静态路径生成
   * */
  private static generateDefaultPath(): string {
    const defaultDir = `${getContext().cacheDir}/web_download`
    const fileName = WebDownloadFileHelper._webDownloadItem?.getSuggestedFileName()
      || `download_${Date.now()}.bin`
    return `${defaultDir}${fileName}`
  }

  protected handleDownloadSuccess(): void {
    this.cleanupDownloadSession()
    WebDownloadFileHelper.closeDownloadPopUpWindow()
    promptAction.showToast({ message: '文件保存成功' })
  }

  protected handleDownloadFailure(message: string): void {
    this.cleanupDownloadSession()
    WebDownloadFileHelper.closeDownloadPopUpWindow()

    promptAction.showToast({ message })
  }

  // 重写抽象类方法
  protected handleDownloadStart(): void {
    WebDownloadFileHelper.openDownloadPopUpWindow()
    WebDownloadFileHelper._webDownloadItem = this.webDownloadItem
  }

  protected handleProgressUpdate(progress: number): void {
    WebDownloadFileHelper._downloadProgress = progress
    EmitterUtil.post<number>(EventIdConstants.DOWNLOAD_PROGRESS_EVENT_ID, progress)
  }

  /* *
   * 实例执行下载
   * */
  private executeDownload(path: string) {
    try {
      this.prepareDirectory(path)
      WebDownloadFileHelper._webDownloadItem!.start(path)
      WebDownloadFileHelper._downloadProgress = 0
    } catch (error) {
      this.handleError(error as BusinessError)
    }
  }

  /**
   * 停止当前下载
   */
  static cancelDownload() {
    if (WebDownloadFileHelper._webDownloadItem) {
      WebDownloadFileHelper._webDownloadItem.cancel()
      WebDownloadFileHelper.instance.cleanupDownloadSession()
      WebDownloadFileHelper.closeDownloadPopUpWindow()
      promptAction.showToast({ message: '下载已取消' })
    }
  }

}