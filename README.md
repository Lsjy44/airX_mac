## 和 libairx 交互的流程

四个角色：我方App，我方lib，对方App，对方lib

### App启动

- App调用lib，初始化，告知端口等配置
- App调用lib，启动发现服务、数据服务，绑定回调函数

### 文本服务

- 我方App自己检测到剪贴板变化
- 我方App调用lib，群发新文本
- 我方lib给所有当前Peer群发文本数据
- 每个Peer上面的lib收到后，调用其App，调用提前绑定好的回调函数
- 对方App通过回调函数得知新文本来了

### 数据服务：发送文件、等待接收

- 我方App调用lib，获取Peer列表
- 我方App让用户选择文件和Peer
- 我方App调用lib，告知文件路径和对方地址
- 我方lib读取文件大小信息，发送给对方
- 对方lib收到后，调用其App，调用提前绑定好的回调函数
- 对方机器上弹窗：是否接收

### 数据服务：拒绝接收文件

- 对方机器上弹窗：是否接收
- 对方用户拒绝接收
- 对方App调用其lib，告知本机地址和拒绝接收的选择
- 对方lib发送拒绝接收的消息给我方
- 我方lib收到后，调用App，调用提前绑定好的回调函数
- 我方App通过回调函数得知对方拒绝接收的噩耗
- 我方App弹窗：对方拒绝接收

### 数据服务：同意接受文件

- 对方机器上弹窗：是否接收
- 对方用户同意接收
- 对方App调用其lib，告知本机地址、同意接收的选择，并分配一个FileId
- 对方App做好接受文件的准备
- 对方lib发送同意接收的消息和FileId给我方
- 我方lib收到后，调用App，调用提前绑定好的回调函数
- 我方App通过回调函数得知同意接收和FileId
- 我方lib开始读取文件
- 我方lib把文件分块发送给对方
- 我方App随时通过回调函数得知发送进度
- 对方lib收到每一分块后，都调用其App，调用提前绑定好的回调函数
- 对方App通过回调函数得知新文件块来了
- 对方App把新文件块写入本地，并能实时计算出进度

### 数据服务：对方中途取消文件接收

- 书接上回，我方lib把文件分块发送给对方
- 我方App随时通过回调函数得知发送进度
- 对方lib收到某一分块后，不收了，关闭了连接
- 我方lib发送失败、重发指定次数后，认定对方不想收了
- 我方lib调用App，调用提前绑定好的回调函数
- 我方App通过回调函数得知对方不想收了

### 数据服务：我方中途取消文件发送

- 还没做

### 以上所有数据的发送过程，均带有
- 校验机制
- 重传机制
- 且本身基于TCP

---

## 发现服务工作流程

两个角色：我方lib，其他方libs

- 我方lib发现服务启动之后，以UDP广播发送发现包，发2遍
- 其他libs收到广播后，把我方加入其Peer List，然后给我方单发UDP发现包，发2遍
- 此时我方的行为和上一步一样，把其他方加入自己的Peer List，**但不再回复发现包**
- 至此，整个局域网内的所有libairx，能够及时感知到彼此的存在，形成双向完全图

---
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
