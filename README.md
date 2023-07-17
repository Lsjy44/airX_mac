## 目录结构

所有代码在AirX目录下

- AirXApp.swift: 程序的入口点，不过没有main函数。这个文件定义了菜单、窗口、菜单点了后的行为、和所有AirX的回调函数

- AppDelegate.swift: 生命周期的回调函数，内含初始化AirX、初始化谷歌登录、防止重复运行

- Bridge: 这个目录包含AirXBridge.h，用于让swift去调用libairx
    - AirXWrapper.m: 没有用到
    - AirXmac-Bridging-Header.h: 没有用到
    - AirXBridge.h: 从libairx那里搞来的自动生成的头文件
    - UnsafeString.swift: 用于从原始指针和Swift的String之间相互转换

- Model: 这个目录包含数据模型
    - Peer.swift: 定义Peer，Peer是指局域网内的其他AirX用户
    - ReceiveFile.swift: 定义正在接受着的文件

- ViewModel: 定义全局状态(State)，所谓状态是指这样一类数据，我们希望每当它们发生改变，都能及时体现在UI上。例如进度条就是很好的例子
    - GlobalState.swift: 包含AirX运行状态
    - TextNoticeViewModel.swift: 包含收到的最新文本

- Enum: 这个目录定义了所有枚举类
    - CredentialType.swift: 密码的存储类型（明文？token？还是Google token）
    - ThemeMode.swift: 定义两种主题模式(Light/Dark)
    - FileSendingStatus.swift: 和libairx对应的1-8的数字代表不同的文件传输状态

- Window: 这个目录定义了所有窗口。注意只是定义窗口，而窗口的实际内容则在View目录里
    - FileNoticeWindow.swift: 来新文件的窗口的大小、位置、使用哪个View
    - PeerPickerWindow.swift: 发文件时选Peer的窗口的大小、位置、使用哪个View

- View: 这个目录定义了窗口们显示的实际内容。可以发现他和Window的数量是不一致的，因为有的Window定义在目录里，是文件形式，而有的Window定义在AirXApp.swift中
    - FileNoticeView.swift: 来新文件的窗口内容
    - TextNoticeView.swift: 来新文本的窗口内容
    - ControlPanelView.swift: 控制面板窗口内容。下一步我们要把它改成设置页面
    - LoginView.swift: 登录页面
    - AboutView.swift: 关于的页面
    - PeerPickerView.swift:  选Peer页面

- Data: 定义了基本数据结构
    - BlockingQueue.swift: 阻塞队列

- Worker: 定义后台工作的线程
    - FileWriterWorker.swift: 文件写入的worker，内含一个阻塞队列，只要队列里有了新的文件写入任务(哪个文件、写在哪里、写什么)就立刻执行

- Service: 定义AirX服务相关的函数
    - AirXService.swift: 对AirXBridge的原版函数进行封装，自动完成字符串到原始指针之间的转换、自动管理内存，方便调用libairx
    - AirXCloud.swift: 所有的airx网络调用，用于和Airx服务器进行交流

- Util: 工具类都在这里
    - ThemeUtils.swift: 定义主题色的颜色值
    - Defaults.swift: 对UserDefaults的封装，把用户设置保存在本地，实现对用户设置的记忆
    - UIUtils.swift: 对UI操作的封装，比如方便的打开选择文件窗口等等
    - AccountUtils.swift: 对airx账户的操作，比如登出、管理黑名单等等
    - FileUtils.swift: 对文件的操作，比如方便的转换win/mac格式的目录、获取“下载”文件夹的实际目录等等

- Extension: 对swift既有的类的扩展
    - Versions.swift: 对Bundle类赋予直接读取本app的版本号的能力
    - StringHash.swift: 对String类赋予获得当前String内容的sha256哈希的能力
    - FileHandleEnsureLength: 为FileHandle类赋予提前占用好N字节空间方便写入的能力
    - ViewWrapContent: 为SwiftUI中的View提供WrapContent（即，尽可能小，小到刚好足以包裹自己的所有内容）的能力
    - StringFromLengthenPointer: 为String类提供从原始指针复制内容、并控制字节数的能力
