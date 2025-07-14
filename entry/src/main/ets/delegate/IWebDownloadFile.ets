import { webview } from '@kit.ArkWeb'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'

const TAG = 'WebDownloadFileHelper'

/**
 * @dec web下载文件抽象类,
 * @author ZhangHuiXin,
 * @param
 * @returns void
 * @date 2025/3/11 20:26,
 */
export abstract class IAbstractDownloadHandler {
  public webDownloadDelegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate()
  protected webDownloadItem: webview.WebDownloadItem | null = null
  protected downloadProgress: number = 0
  protected controller: webview.WebviewController | null = null
  protected isCustomPath: boolean = false

  /**
   * 设置下载委托
   * */
  setDownloadDelegate(controller: webview.WebviewController, delegate?: webview.WebDownloadDelegate) {
    if (delegate) {
      this.webDownloadDelegate = delegate
    }
    try {
      this.controller = controller
      this.controller.setDownloadDelegate(this.webDownloadDelegate)
      this.setupDelegateCallbacks(this.webDownloadDelegate)
    } catch (error) {
      this.handleError(error as BusinessError)
    }
  }

  /**
   * 启动文件下载
   * @param customPath 自定义存储路径（需包含文件名）
   */
  startDownload(customPath?: string) {
    if (!this.webDownloadItem) {
      throw new Error('DOWNLOAD_NOT_INITIALIZED')
    }

    try {
      const effectivePath = this.validatePath(customPath)
      this.prepareDirectory(effectivePath)

      this.webDownloadItem!.start(effectivePath)
      this.downloadProgress = 0
      this.isCustomPath = !!customPath
    } catch (error) {
      this.handleError(error as BusinessError)
    }
  }

  /**
   * 准备存储目录
   */
  prepareDirectory(fullPath: string) {
    const dirPath = fullPath.substring(0, fullPath.lastIndexOf('/'))

    if (!this.checkPathExists(dirPath)) {
      fileIo.mkdirSync(dirPath)
    }
  }

  /**
   * 抽象方法 - 处理下载开始
   * */
  protected abstract handleDownloadStart(): void

  /**
   * 抽象方法 - 更新进度
   * */
  protected abstract handleProgressUpdate(progress: number): void

  /**
   * 抽象方法 - 处理下载成功
   * */
  protected abstract handleDownloadSuccess(): void

  /**
   * 抽象方法 - 处理下载失败
   * */
  protected abstract handleDownloadFailure(message: string): void

  /**
   * 通用文件保存方法
   * */
  protected async saveFile(filePath: string): Promise<void> {
    const context = getContext()
    const fileName = this.extractFileName(filePath)
    const saveOptions = new picker.DocumentSaveOptions()
    saveOptions.newFileNames = [fileName]

    try {
      const documentSaveResult = await new picker.DocumentViewPicker(context).save(saveOptions)
      await this.copyFileContents(filePath, documentSaveResult[0])
    } catch (error) {
      throw new Error(`文件保存失败: ${(error as BusinessError).message}`)
    }
  }

  /**
   * 错误处理
   * */
  protected handleError(error: BusinessError) {
    console.error(`${TAG} ErrorCode: ${error.code}, Message: ${error.message}`)
    this.cleanupDownloadSession()
  }

  /**
   * 清理下载会话
   * */
  protected cleanupDownloadSession() {
    this.webDownloadItem = null
    this.downloadProgress = 0
  }

  /**
   * 路径验证与处理
   */
  private validatePath(customPath?: string): string {
    if (customPath) {
      return this.ensureFileExtension(customPath)
    }
    return this.generateDefaultPath()
  }

  /**
   * 生成默认下载路径
   */
  private generateDefaultPath(): string {

    const defaultDir = `${getContext(this).cacheDir}/web_download`
    const fileName = this.webDownloadItem?.getSuggestedFileName()
      || `download_${Date.now()}.bin`
    return `${defaultDir}${fileName}`
  }

  /**
   * 确保文件扩展名正确
   */
  private ensureFileExtension(path: string): string {
    const suggestedName = this.webDownloadItem?.getSuggestedFileName() || ''
    const expectedExt = suggestedName.split('.').pop() || ''
    const currentExt = path.split('.').pop() || ''

    return currentExt === expectedExt ? path : `${path}.${expectedExt}`
  }

  /**
   * 路径存在性检查
   */
  private checkPathExists(path: string): boolean {
    try {
      return fileIo.accessSync(path)
    } catch {
      return false
    }
  }

  /**
   * 初始化委托回调
   * */
  private setupDelegateCallbacks(delegate: webview.WebDownloadDelegate) {
    delegate.onBeforeDownload((item: webview.WebDownloadItem) => {
      this.webDownloadItem = item
      this.handleDownloadStart()
    })

    delegate.onDownloadUpdated((item: webview.WebDownloadItem) => {
      this.downloadProgress = item.getPercentComplete()
      this.handleProgressUpdate(item.getPercentComplete())
    })

    delegate.onDownloadFailed((item: webview.WebDownloadItem) => {
      this.handleDownloadFailure('文件下载失败')
    })

    delegate.onDownloadFinish(async (item: webview.WebDownloadItem) => {
      try {
        const filePath = item.getFullPath()
        if (!this.isCustomPath) {
          await this.saveFile(filePath) // 仅非自定义路径需要另存操作
        }
        this.handleDownloadSuccess()
      } catch (error) {
        this.handleDownloadFailure(this.isCustomPath ? '文件下载失败' : '文件保存失败')
      }
    })
  }

  /**
   * 提取文件名
   * */
  private extractFileName(path: string): string {
    const match = path.match(/[^\\/]+$/)
    return match ? match[0] : `file_${Date.now()}`
  }

  /**
   * 复制文件内容
   * */
  private async copyFileContents(sourcePath: string, destPath: string) {
    const sourceFd = await fileIo.open(sourcePath, fileIo.OpenMode.READ_ONLY)
    const stat = await fileIo.stat(sourcePath)
    const buffer = new ArrayBuffer(stat.size)

    await fileIo.read(sourceFd.fd, buffer)
    await fileIo.close(sourceFd)

    const destFile = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
    await fileIo.write(destFile.fd, buffer)
    await fileIo.close(destFile.fd)
  }
}



