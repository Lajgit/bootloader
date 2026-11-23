# 通用Bootloader编译与固件命名

2026-11-23当前选择：`BOOT_BOARD_DIAOQIU=6`，仅SD卡升级。最新适配、完整原/新代码对照及验证见本文末尾“DIAOQIU掉珠机上球盘”章节；前面的五板型记录为历史说明。

在 `App/Src/app_bootloader.c` 的 `Boot_BoardGetId()` 中选择板型后重新编译：

```c
BootBoardId_t board_id = BOOT_BOARD_WUSONG;
```

Keil 的 `Bootloader_F407` 目标和 EIDE 的两个 AC5 目标均已配置编译后任务。
Windows 下使用系统自带的 `powershell.exe`，脚本以 UTF-8 BOM 保存以兼容 PowerShell 5.1；通过当前工具链的 `fromelf.exe`，
从本次生成的同一个 AXF 自动导出 HEX 和 BIN，保存在 `MDK-ARM/firmware/`。

| board_id | HEX | BIN |
| --- | --- | --- |
| `BOOT_BOARD_DANJIE` | `Bootloader_Danjie.hex` | `Bootloader_Danjie.bin` |
| `BOOT_BOARD_PANTAO` | `Bootloader_Pantao.hex` | `Bootloader_Pantao.bin` |
| `BOOT_BOARD_NIUDAN` | `Bootloader_Niudan.hex` | `Bootloader_Niudan.bin` |
| `BOOT_BOARD_WUSONG` | `Bootloader_Wusong.hex` | `Bootloader_Wusong.bin` |
| `BOOT_BOARD_YITONG` | `Bootloader_Yitong.hex` | `Bootloader_Yitong.bin` |
| `BOOT_BOARD_DIAOQIU` | `Bootloader_DIAOQIU.hex` | `Bootloader_DIAOQIU.bin` |

同板型重新编译会覆盖该板型的两个导出文件，其他板型的文件保留。
Keil 原有的 `Bootloader_F407/Bootloader_F407.axf/.hex` 输出设置保持不变。
导出目录已加入 `.gitignore`。

## 导出校验与手动执行

脚本接受上述六种板型，板型选择格式保持为上面的单行赋值。
板型源文件比 AXF 新时拒绝导出，需先重新编译，避免给上一板型的固件改名。
HEX 和 BIN 均成功转换，且 BIN 大小在 8～49152 字节、栈指针与复位向量有效后，
才覆盖正式导出文件；转换失败时任务返回非零值。

需要单独执行时，在仓库的 `MDK-ARM` 目录运行以下命令。
示例工具路径按实际 Keil 安装位置修改，自动编译任务无需修改该示例路径。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\export_firmware.ps1 `
  -AxfPath .\Bootloader_F407\Bootloader_F407.axf `
  -FromElfPath E:\Keil5\ARM\ARMCC\bin\fromelf.exe
```

这些文件只包含 Bootloader，烧录地址为 `0x08000000`。
它们不包含 APP，不应替代 SD 升级使用的 `danjie.bin`、`pantao.bin`、
`niudan.bin`、`wusong.bin` 或 `yitong.bin`；APP 起始地址仍为 `0x0800C000`。

## 修改范围和验证步骤

- `MDK-ARM/export_firmware.ps1`：新增导出脚本，读取现有板型选择并校验输出。
- `MDK-ARM/Bootloader_F407.uvprojx`：原编译后命令为空，改为调用该脚本；补列已有的 `app_ws2812.c`，避免非武松板型出现 RGB 符号链接失败，不修改灯效源码。
- `MDK-ARM/.eide/eide.yml`：原两个 AC5 目标的 `afterBuildTasks` 为空，均接入同一脚本。
- `App/Src/app_bootloader.c`：仅更新板型选择旁的导出说明注释，固件逻辑不变。
- `.gitignore`：增加生成目录规则。

依次选择五个板型并执行 Keil Rebuild，检查日志中的 `Exported` 行和四组命名文件。
核对 HEX 校验和、地址及 BIN 内容一致，且 Bootloader 未超出前48KB。
修改板型后不重新编译，单独执行脚本应报错；非法板型、缺失输入或转换失败时
也应返回非零值，并保留已有正式导出文件。EIDE 的两个 AC5 目标需分别回归构建。
本功能只改变编译后的导出，不改变升级协议；烧录和实机运行需另行验证。

## 此前导出功能验证结果

五种板型均实际通过 Keil 编译及 After Build 自动导出，并从各自 AXF 执行
`Boot_BoardGetId()` 确认返回值与文件名对应：

| 板型 | 编译结果内的Board ID | BIN字节数 |
| --- | --- | --- |
| 弹界 | 1 | 21236 |
| 蟠桃 | 2 | 21236 |
| 扭蛋 | 3 | 21236 |
| 武松 | 4 | 20820 |
| 一统天下 | 5 | 20824 |

五组 HEX 校验和、地址范围及 HEX/BIN 内容一致性检查均通过，五组文件可同时保留。
非法板型、换板型未重编译、缺失AXF、转换失败、误用APP镜像这五种场景均返回非零值，
已有正式输出内容未变。EIDE配置已解析，并按两个目标的变量展开执行了导出命令；
完整EIDE编译流程和实机烧录尚未验证。

## 一统天下板型与红色成功提示

新增 `BOOT_BOARD_YITONG=5`，原板型1～4编号保持不变，默认选择仍为武松。
构建一统天下时，将 `Boot_BoardGetId()` 中的单行选择改为：

```c
BootBoardId_t board_id = BOOT_BOARD_YITONG;
```

该板型的SD升级文件为APP镜像 `yitong.bin`；Bootloader导出文件为
`MDK-ARM/firmware/Bootloader_Yitong.hex/.bin`。APP必须链接到 `0x0800C000`，
空间限制为 `0x94000`，串口OTA缓存上限为261888字节。
当前一统天下APP工程的Keil配置仍需按此布局调整并重新编译，本次未修改APP或球盘工程。
Bootloader本身仍通过SWD写入 `0x08000000`，不能将Bootloader BIN当作APP升级文件。

一统天下使用USART2 PD5/PD6、115200 8N1连接球盘，不启用主板RGB定时器；
等待/失败用PC13指示。SD、串口INSTALL和恢复安装成功后使用球盘既有协议：

1. 依次发送5帧 `04/02`，Data3=1～5、Data4=0（红色）、补充位=0（常亮）。
2. 等待1000ms。
3. 依次发送5帧 `04/02`，Data3=1～5、Data4=0、补充位=1（关闭），然后继续启动APP。

按用户选择沿用球盘当前亮度，不发送 `04/04` 亮度命令；亮度为0时没有可见提示。
提示帧不要求ACK，球盘未供电或通信断开时仍继续启动，实际灯效和机械时序尚未上板验证。
一统天下不发送武松的 `04/01` 通道灯或 `04/07` 场景命令，避免与数码管协议冲突。

本次新增修改点及前后行为：

- `App/Inc/app_board.h`：原板型1～4增加编号5；`App/Inc/app_sd.h`增加yitong.bin。
- `App/Src/app_bootloader.c`：`Boot_BoardGetFirmwareFileName`增加文件名分支；
  `Boot_BallSend`增加补充位参数，原武松调用仍传0；`Boot_LightSuccess`增加一统天下红灯分支。
  等待、失败、成功路径延时、SD向量检查及`JumpToApplication`的USART2释放条件包含新板型。
- `Core/Src/main.c`：原仅武松初始化USART2，扩展为武松和一统天下；其他板型仍初始化TIM3。
- `Core/Inc/usart.h`、`Core/Src/usart.c`：仅更新USART2用途注释，引脚和波特率不变。
- `MDK-ARM/export_firmware.ps1`：增加板型5到Bootloader_Yitong的名称映射。

已执行336项ARM仿真断言：一统天下Bootloader 46、原武松回归35、一统天下球盘255。
测试直接编译生产源码，以测试桩提供UART/Flash/时钟接口；验证SD和串口成功各仅等待一秒、
失败不触发成功灯效、报文CRC及亮灭参数正确；将相同10帧回放到真实球盘接收器和RGB编码器，
验证5颗灯的GRB波形仅红色通道有数据、亮度不变、全灭生效且没有调用数码管控制。
武松原3帧提示仍与原有固定报文一致。真实断电恢复、串口供电及实机灯效仍尚未验证。

## SD与启动异常修复（2026-11-06）

复现依据：原SD接收循环多写1字节；SD第一块成功而后续失败时，启动流程仍可能凭前两个向量跳转。修复后的预期是精确接收、低速探卡、正确寻址，以及任何已开始擦写的失败都留在升级模式。

本仓库根目录为`E:/单片机项目/ChatGPT单片机项目/通用bootloader/Bootloader`。以下路径均相对该目录；具体原代码、修改后代码见本次Git差异。

| 文件 / 模块或函数 | 原代码或行为 | 修改后 / 原因与影响 |
| --- | --- | --- |
| App/Src/fatfs_sd.c / SD_RxDataBlock | `do ... while(len--)`写入len+1次 | 改为`while (len > 0U)`并在写入后递减；512字节扇区、16字节CSD及多块读取不再越界 |
| Core/Src/spi.c / MX_SPI1_Init | 初始分频8，SPI1为10.5MHz | 初始分频256，84MHz/256=328.125kHz；只改变探卡初始速率 |
| App/Src/fatfs_sd.c / SD_disk_initialize | 每次直接以现有高速探卡 | 每次先设256分频；成功后设8分频，任一HAL初始化失败均保持STA_NOINIT；重新探卡同样降速 |
| App/Src/fatfs_sd.c / SD_disk_initialize、SD_disk_read/write | 以CT_SD2决定是否换算字节地址，SDv2标准容量卡未统一设512字节块 | 按CT_BLOCK判断；所有字节寻址卡发送CMD16=512，保留SDv1/MMC及SDHC/SDXC分支 |
| App/Src/app_bootloader.c / Boot_TrySdUpgrade | 无法向调用方区分“未更新”和“已破坏APP后失败”；先写入向量 | 增加内部app_modified输出；擦除前置位；先写并读回核对正文，全部成功后最后写8字节向量并核对。保持原SD最大尺寸和Flash布局 |
| App/Src/app_bootloader.c / App_Bootloader | SD失败后仍可按向量合法启动 | 接收app_modified到既有recovery_pending；擦写失败禁止回退跳转，保留错误提示并进入串口升级。无文件或预检拒绝且未擦写时，允许保留原APP启动 |

这些修复位于公共SD路径，覆盖五种板型。串口OTA报文、安装缓存、设置区以及各板型成功灯效不变。向量最后写入可防止已测试的正文失败及其后重启被误判为有效APP；真实掉电及Flash编程故障仍须实机验证，不保证无硬件条件下的任意掉电原子性。

武松APP同时修复启动交接：HAL_Init前调用SystemCoreClockUpdate；Device_Init后的输入滤波初始化原子清计数并开放输入，在此之前SysTick扫描和EXTI业务均返回。它们位于武松仓库，不在通用Bootloader内增加机型分支或修改公共跳转时钟。

### 本机编译与回归

```powershell
Set-Location -LiteralPath 'E:/单片机项目/ChatGPT单片机项目/通用bootloader/Bootloader'
New-Item -ItemType Directory -Force -Path './MDK-ARM/build' | Out-Null
$taskArgs = '-r "./MDK-ARM/Bootloader_F407.uvprojx" -t "Bootloader_F407" -o "./MDK-ARM/build/rebuild.log"'
$taskProcess = Start-Process -FilePath 'E:/Keil5/UV4/UV4.exe' -ArgumentList $taskArgs -WindowStyle Hidden -Wait -PassThru
if (-not (Select-String -LiteralPath './MDK-ARM/build/rebuild.log' -Pattern '- 0 Error\(s\)' -Quiet)) { throw 'Build failed' }
Get-Content -LiteralPath './MDK-ARM/build/rebuild.log' -Tail 10

# 此工作区沿用已有ARMCC、Unicorn和pyelftools仿真环境，材料位于忽略目录。
Set-Location -LiteralPath 'E:/单片机项目/ChatGPT单片机项目/新弹珠机'
python ./tmp/verification/run_tests.py
python ./tmp/verification/startup_audit/startup_audit.py
python ./tmp/bootloader_yitong_20261105/validation/run_yitong_tests.py
```

新增启动/SD回归共14组，其中SD底层42项断言：覆盖四类卡初始化、读写地址、探卡降速、HAL初始化失败、512/16字节边界、多块读取、SD预检拒绝、擦除/读取/写入/比较/向量写入失败、正文失败后重启；已有武松/一统天下Bootloader共81项SD、串口OTA及成功灯效断言同时通过。硬件接口为测试桩或仿真内存，测试源从当前生产文件读取，不代表实卡、实物掉电或机械验证。

### 烧录与实机回归（尚未验证）

1. 在Boot_BoardGetId中选择实际板型并编译，确认导出名称与板型一致。更新Bootloader必须使用SWD；仅更新wusong.bin不会替换Bootloader。
2. 武松先经SWD写入新的MDK-ARM/firmware/Bootloader_Wusong.hex，再写武松APP或用新Bootloader执行APP升级。控台小卡不修改，微动板程序本次不变。
3. 逻辑分析仪确认探卡阶段约328.125kHz、成功后10.5MHz；分别测试SDv1/MMC、SDv2标准容量与高容量卡，并验证重新探卡。
4. 测试无文件、非法旧地址文件、正常升级、读卡/写入中断、重启后恢复；未完成正文不得跳APP，串口升级模式应可恢复安装，设置区应保留。真实掉电测试应保留SWD恢复手段。
5. 回归五种板型串口HELLO/BEGIN/DATA/END/INSTALL与缓存恢复，确认原成功灯效；武松12路通道灯仍全亮1秒，一统天下仍沿用当前亮度红灯1秒。

本次五板型均Keil Rebuild为0错误、5个现有警告；从各AXF执行Boot_BoardGetId核对了真实返回值，全部HEX/BIN校验和、地址范围和逐字节一致性检查通过：

| 板型 | Board ID | 最新BIN字节数 |
| --- | --- | --- |
| Bootloader_Danjie | 1 | 21432 |
| Bootloader_Pantao | 2 | 21432 |
| Bootloader_Niudan | 3 | 21432 |
| Bootloader_Wusong | 4 | 21036 |
| Bootloader_Yitong | 5 | 21040 |

产物已同步到本仓库MDK-ARM/firmware；manifest.json包含源码摘要、固件SHA256和实际构建日志路径。构建使用新弹珠机tmp/bootloader_yitong_20261105内的独立工程副本，所有Git跟踪输入先同步，编译后核对三个修改源码与本仓库一致；生产board_id保持武松4，未修改用户正式工程目标。


## DIAOQIU掉珠机上球盘（2026-11-23）

本次用户明确要求：同步上球盘链接地址/中断向量表，新增DIAOQIU板型；仅SD卡升级，引导粉灯、成功绿灯。硬件依据为掉球机仓库Diaoqiu.tel与已确认的WS2812B/GRB，两路PC6/PC7分别36/49颗，SD为PA4片选、PA5时钟、PA6输入、PA7输出。原目录的Bootloader_F407仍是同一通用工程，不新建Bootloader工程。

修改前，上球盘APP链接于0x08000000，通用Bootloader仅有五板型，默认旧板型的RGB引脚和串口流程与本机不匹配。直接搭配会发生地址重叠、错误灯效引脚或进入未使用的串口恢复。现在以板型6选择掉珠机专用路径，其他板型编号不变。

### 行为与文件

- 当前Boot_BoardGetId选择BOOT_BOARD_DIAOQIU=6；只识别SD卡根目录的APP镜像`DIAOQIU.bin`。导出的`Bootloader_DIAOQIU.hex/.bin`是Bootloader自身，不能放到SD卡当APP。
- Bootloader位于0x08000000，最大前48KB；APP链接地址及VTOR为0x0800C000，末端不超过0x080A0000（最大0x94000）。0x080E0000设置区仍保留。沿用原APP上界，不扩展到缓存或设置区。
- DIAOQIU不初始化USART1/2，不检查RTC串口升级请求、不安装旧OTA缓存，也不进入OTA_Run。其他五板型的串口/缓存功能保留。
- 一进入App_Bootloader即两路85颗保持原表粉色RGB=(255,64,129)。SD升级完整写入、回读比较且向量有效后亮绿RGB=(0,255,0)一秒，再跳转APP；APP接管后显示其自身灯效。
- 无卡/无文件且旧APP有效时直接启动旧APP。非法镜像在擦除前拒绝；若旧APP仍有效则启动旧APP。无有效APP或已开始擦写后失败，保持粉灯等待，处理SD卡后复位重试；不额外增加热插拔重试、文件删除、串口恢复或失败颜色。
- SD文件先检查大小及栈/复位向量，并确认DIAOQIU入口位于本次文件内，拒绝仅向量/截断镜像，再擦写；正文逐块回读比较，最后写向量。仅增加DIAOQIU到已有预检条件，保留原SD安装结构。
- PC6/PC7使用TIM3 CH1/CH2，84MHz/(6+1)/(14+1)=800kHz；GRB高位先发，0/1占空值4/10，尾256个低时隙=320us。复用原缓冲，36/49颗分路发送；最长约1.8ms，等待3ms后停止DMA再复用，输出保持低电平。未改旧板型的编码路径。
- 引导GPIO按本机现有APP关闭卡机、电机、锁及PB3/PB4负载；PB4不作为RGB输出。跳转前停止两路RGB DMA和TIM3，跳过未初始化的UART反初始化，再沿用原清中断、VTOR/MSP跳转流程。

### 每处修改与影响范围

下表路径相对本Bootloader目录；逐行原(-)/新(+)代码全文在本节末尾。修改前工作区曾选择DANJIE，编辑期间选择回到WUSONG；最终按用户要求选择DIAOQIU。没有把其他来源的未提交修改并入本次功能。

| 文件/模块 | 函数/位置 | 原代码/行为 → 修改后代码/行为；原因/影响 |
| --- | --- | --- |
| App/Inc/app_board.h | BootBoardId_t | 五板型 → 追加BOOT_BOARD_DIAOQIU=6；1~5不变 |
| App/Inc/app_sd.h | 文件名宏 | 无掉珠机文件 → FileName_Diaoqiu="DIAOQIU.bin"；只扩展SD文件选择 |
| App/Src/app_bootloader.c | Boot_BoardGetId、Boot_BoardGetFirmwareFileName | 旧选择/无对应文件 → 选择6并返回DIAOQIU.bin；导出与SD读取对应 |
| 同上 | Boot_LightWaiting/Success/Error | 旧RGB/球盘提示 → DIAOQIU本机粉灯、成功绿灯1秒、失败保持粉灯；其他板型分支不变 |
| 同上 | JumpToApplication | 无条件反初始化UART1 → DIAOQIU停两路RGB DMA/定时器，其他板型仍反初始化原串口；避免未初始化句柄与DMA影响APP |
| 同上 | Boot_TrySdUpgrade | 原4/5板型向量预检 → 加入6；成功后跳过旧板载灯闪烁；避免旧地址APP擦掉现有应用 |
| 同上 | App_Bootloader | 所有板型共用OTA/缓存入口 → DIAOQIU先进入SD专用分支，有效APP才跳，无效/写失败粉灯等待复位；不启用串口 |
| App/Src/app_ws2812.c | Light_SetAllColor | 旧159颗编码/旧通道 → DIAOQIU先走36/49颗GRB高位编码与320us复位；原分支保留 |
| Core/Src/main.c | main初始化 | 总是初始化UART1 → DIAOQIU跳过；UART2仍仅旧4/5板型初始化 |
| Core/Src/tim.c | MX_TIM3_Init、HAL_TIM_MspPostInit | 原PSC5/旧GPIO → DIAOQIU PSC6、PC6/PC7 AF2；其他板型照旧 |
| Core/Src/gpio.c | MX_GPIO_Init | 未初始化本机执行器输出 → 仅DIAOQIU按本机APP低电平关闭，RGB先低；不影响旧板型 |
| MDK-ARM/export_firmware.ps1 | exportNames | 五个映射 → 加Bootloader_DIAOQIU；继续同AXF导出HEX/BIN并校验前48KB/向量 |
| README.md | 当前状态、文件表、本节 | 增加第六板型、最新流程、修改对照及验证，历史记录保留 |

### 实际验证结果和复现入口

ARMCC5.05 update1 build106全量编译链接：Bootloader37个编译单元，0错误、5个既有警告；Code/RO/RW/ZI=20008/460/124/21716字节。当前DIAOQIU BIN为20592字节，栈0x20005550、Reset=0x08000229；从真实AXF执行Boot_BoardGetId得到6。

导出脚本实际执行成功，HEX/BIN地址、校验和及内容一致性通过：

- Bootloader_DIAOQIU.bin SHA256：34a0d72daec34a4d786a1a3eaef5449853824e1e00aac1081364f4b92e4874df。
- Bootloader_DIAOQIU.hex SHA256：a0d7f2e1939691d2ae596c953f24601b3f79d62553666f9e7ab038b966673701。

Unicorn执行当前真实C源码：SD 14场景/1646项C断言，覆盖正常、无卡有效/无效APP、错误Reset/栈、短/超大文件、仅向量/入口越过文件末尾、擦除失败、读/写/比较/最终向量写失败。检查未调用串口、不消费RTC请求、不改Bootloader/设置区；真实JumpToApplication执行到APP复位入口，VTOR正确且RGB停用。灯驱动8471项、GPIO/TIM映射21项检查通过；旧武松/一统天下按当前源码仅替换板型选择生成临时测试输入，原SD/串口/灯效回归共83项通过。另有上板真实SystemInit重定位及整机软件回归，详见掉球机文档第18节。

完整临时验证工具、可复制的编译/导出/测试命令，以及APP地址差异均保存在：
`E:\单片机项目\ChatGPT单片机项目\掉球机\硬件引脚映射与外设资源表.md`第18节。工具仅提取到%TEMP%\diaoqiu_game_review，不加入固件源码/依赖。编译日志/AXF在该目录sd_boot\Bootloader_DIAOQIU\，正式命名的Bootloader HEX/BIN在本仓库MDK-ARM\firmware\（生成目录已忽略）。

原Keil要求的ARMCC5.06 update6及完整IDE/EIDE流程本次尚未验证。本机使用现有5.05直接按原uvprojx清单编译，没有改工程工具链/STM器件设置。APM实物烧录、SD实卡/真实掉电、85颗灯实际颜色/PWM、启动及机电输出均**尚未验证**，软件替身不代表真实硬件。

### 烧录与SD升级步骤（实机尚未执行）

1. 按掉球机文档18节编译并核对两份输出：本仓库MDK-ARM\firmware\Bootloader_DIAOQIU.hex；%TEMP%\diaoqiu_game_review\sd_boot\Diaoqiu\DIAOQIU.bin（25736字节，APP起始0x0800C000）。
2. 断电接SWD，先断开执行器负载，使用支持实际APM32F407VGT6的工具/算法识别芯片。备份原固件与0x080E0000起128KB设置；不改保护/选项字节。Bootloader首次安装及后续更换仍用SWD。
3. 将Bootloader_DIAOQIU.hex烧到0x08000000并回读校验；APP可同时用其firmware.hex烧到0x0800C000，或由SD升级首次安装。若工具整片擦除会清设置，应记录并重设，不宣称保留。
4. SD卡使用当前FatFs配置支持的FAT卷，断电放入根目录DIAOQIU.bin。只复制APP BIN，不能复制Bootloader BIN或旧0x08000000镜像。此SD卡不是语音模块F盘，不触碰F盘的MP3。
5. 接回逻辑供电后复位：引导粉灯→安装成功绿灯约1秒→APP灯效。首次无有效APP且读卡失败时保持粉灯，检查文件/卡后复位重试，无串口升级入口。
6. 成功后断电取出升级卡或移走DIAOQIU.bin，避免下次上电重复安装。原流程不自动删除/改名升级文件。
7. 实机分别回归无卡旧APP启动、无效/旧地址文件拒绝、正常升级、读卡/写入中断、重新插卡复位后重装；回读设置区与备份一致。示波器核对PC6/7约800kHz、GRB粉/绿和低电平复位；PB4不输出RGB，电机/卡机/锁在Boot阶段保持关闭。
8. 验证APP上电及两板通信、九宫格、转轮、出珠/卡、后台、LCD和语音；本次不修改下板，也不把语音USB盘当SD升级通道。

### 本次完整原/新代码对照

以下diff相对本仓库当前HEAD，README自身不递归嵌入。源码原/新函数、配置及影响均可与上表对应。

~~~diff
diff --git a/App/Inc/app_board.h b/App/Inc/app_board.h
index 5fa38e7..610d705 100644
--- a/App/Inc/app_board.h
+++ b/App/Inc/app_board.h
@@ -18,7 +18,8 @@ typedef enum
     BOOT_BOARD_PANTAO = 2U,
     BOOT_BOARD_NIUDAN = 3U,
     BOOT_BOARD_WUSONG = 4U, // 新武松主控，成功提示使用微动板通道灯
-    BOOT_BOARD_YITONG = 5U // 一统天下主控，成功提示使用球盘5颗RGB
+    BOOT_BOARD_YITONG = 5U, // 一统天下主控，成功提示使用球盘5颗RGB
+    BOOT_BOARD_DIAOQIU = 6U // 掉珠机上球盘，仅SD升级，PC6/PC7本机RGB提示
 } BootBoardId_t;

 BootBoardId_t Boot_BoardGetId(void);
diff --git a/App/Inc/app_sd.h b/App/Inc/app_sd.h
index 679c235..762b2c3 100644
--- a/App/Inc/app_sd.h
+++ b/App/Inc/app_sd.h
@@ -15,6 +15,7 @@
 #define FileName_Niudan "niudan.bin"
 #define FileName_Wusong "wusong.bin" // 新武松APP须链接于0x0800C000
 #define FileName_Yitong "yitong.bin" // 一统天下APP须链接于0x0800C000
+#define FileName_Diaoqiu "DIAOQIU.bin" // 掉珠机上球盘APP须链接于0x0800C000


 FRESULT mount_disk(FATFS *fs, const TCHAR *path, BYTE opt);
diff --git a/App/Src/app_bootloader.c b/App/Src/app_bootloader.c
index 4933714..1ecf08f 100644
--- a/App/Src/app_bootloader.c
+++ b/App/Src/app_bootloader.c
@@ -2,6 +2,7 @@
 #include "app_ws2812.h"
 #include "app_board.h"
 #include "usart.h"
+#include "tim.h"
 #include <stddef.h>
 #include <string.h>

@@ -36,10 +37,10 @@ static uint8_t TxFrame[2U + 6U + 10U + 4U];
 BootBoardId_t Boot_BoardGetId(void)
 {
     /* 中文注释：只修改下一行后重新编译，不使用OTP。
-     * 弹界：BOOT_BOARD_DANJIE；蟠桃：BOOT_BOARD_PANTAO；扭蛋：BOOT_BOARD_NIUDAN；武松：BOOT_BOARD_WUSONG；一统天下：BOOT_BOARD_YITONG。
+     * 弹界：BOOT_BOARD_DANJIE；蟠桃：BOOT_BOARD_PANTAO；扭蛋：BOOT_BOARD_NIUDAN；武松：BOOT_BOARD_WUSONG；一统天下：BOOT_BOARD_YITONG；掉珠机上球盘：BOOT_BOARD_DIAOQIU（仅SD）。
      * 编译后自动在MDK-ARM/firmware生成对应板型的HEX和BIN，保留其他板型文件。
      */
-    BootBoardId_t board_id = BOOT_BOARD_WUSONG;
+    BootBoardId_t board_id = BOOT_BOARD_DIAOQIU;
     return board_id;
 }

@@ -47,6 +48,8 @@ const char *Boot_BoardGetFirmwareFileName(void)
 {
     switch (Boot_BoardGetId())
     {
+    case BOOT_BOARD_DIAOQIU:
+        return FileName_Diaoqiu;
     case BOOT_BOARD_YITONG:
         return FileName_Yitong;
     case BOOT_BOARD_WUSONG:
@@ -172,14 +175,22 @@ static void Boot_BallSend(uint8_t command, uint16_t data, uint8_t expand)
 /* 武松/一统天下等待和失败用板载灯，成功由各自球盘提示；其他板型保持原RGB。 */
 void Boot_LightWaiting(void)
 {
-    if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+        Light_SetAllColor(PINK, RGB_buffer);
+    else if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
         HAL_GPIO_WritePin(LED_GPIO_Port, LED_Pin, GPIO_PIN_RESET);
     else
         Light_SetAllColor(SKYBLUE, RGB_buffer);
 }
 void Boot_LightSuccess(void)
 {
-    if (Boot_BoardGetId() == BOOT_BOARD_WUSONG)
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+    {
+        /* 中文注释：仅上球盘85颗绿灯提示一秒，随后交给APP自己的灯效。 */
+        Light_SetAllColor(GREEN, RGB_buffer);
+        HAL_Delay(1000U);
+    }
+    else if (Boot_BoardGetId() == BOOT_BOARD_WUSONG)
     {
         HAL_GPIO_WritePin(LED_GPIO_Port, LED_Pin, GPIO_PIN_RESET);
         /* 先退出后台跟灯场景，避免微动扫描覆盖全亮；一秒后主动熄灭再交给APP。 */
@@ -205,7 +216,9 @@ void Boot_LightSuccess(void)
 }
 void Boot_LightError(void)
 {
-    if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+        Light_SetAllColor(PINK, RGB_buffer);
+    else if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
         HAL_GPIO_WritePin(LED_GPIO_Port, LED_Pin, GPIO_PIN_SET);
     else
         Light_SetAllColor(RED, RGB_buffer);
@@ -708,7 +721,15 @@ void JumpToApplication(void)
     app_stack = *(volatile uint32_t *)APP_ADDR;
     entry = (AppEntry_t)(*(volatile uint32_t *)(APP_ADDR + 4U));
     __disable_irq();
-    HAL_UART_DeInit(&huart1);
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+    {
+        /* SD专用板型没有初始化串口；跳转前停止RGB定时器与DMA，避免影响APP。 */
+        HAL_TIM_PWM_Stop_DMA(&htim3, TIM_CHANNEL_1);
+        HAL_TIM_PWM_Stop_DMA(&htim3, TIM_CHANNEL_2);
+        HAL_TIM_Base_DeInit(&htim3);
+    }
+    else
+        HAL_UART_DeInit(&huart1);
     if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
         HAL_UART_DeInit(&huart2);
     HAL_DeInit();
@@ -755,12 +776,16 @@ static bool Boot_TrySdUpgrade(bool *app_modified)
     file_size = f_size(&SdFirmwareFile);
     if (file_size < 8U || file_size > APP_MAX_SIZE)
         goto finish;
-    if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
+    if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG ||
+        Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
     {
-        /* 武松和一统天下APP均须链接于0x0800C000；先检查再擦除，拒绝旧地址镜像。 */
+        /* 以上APP均须链接于0x0800C000；先检查再擦除，拒绝旧地址镜像。 */
         if (read_file(&SdFirmwareFile, r_buffer, 8U, &bytes_read) != FR_OK || bytes_read != 8U ||
             !StackPointerIsValid(ReadU32LE(r_buffer)) ||
             !ResetHandlerIsValid(ReadU32LE(&r_buffer[4])) ||
+            /* DIAOQIU还检查入口确实在本次文件内，拒绝只剩向量或被截断的镜像。 */
+            (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU &&
+             (ReadU32LE(&r_buffer[4]) & ~1U) >= APP_ADDR + file_size) ||
             f_lseek(&SdFirmwareFile, 0U) != FR_OK)
             goto finish;
     }
@@ -822,8 +847,9 @@ finish:
     if (programmed)
     {
         Boot_LightSuccess();
-        /* 武松/一统天下的一秒提示已在Boot_LightSuccess完成，其他板型保留原闪烁。 */
-        if (Boot_BoardGetId() != BOOT_BOARD_WUSONG && Boot_BoardGetId() != BOOT_BOARD_YITONG)
+        /* 武松/一统天下/掉珠机的一秒提示已完成，其他板型保留原闪烁。 */
+        if (Boot_BoardGetId() != BOOT_BOARD_WUSONG && Boot_BoardGetId() != BOOT_BOARD_YITONG &&
+            Boot_BoardGetId() != BOOT_BOARD_DIAOQIU)
         {
             for (uint8_t i = 0U; i < 6U; i++)
             {
@@ -842,6 +868,19 @@ void App_Bootloader(void)
 {
     OtaMetadata_t metadata;
     bool recovery_pending = false;
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+    {
+        /* 中文注释：本板仅SD升级，不读串口请求/OTA缓存，不进入串口恢复循环。 */
+        Boot_LightWaiting();
+        if (Boot_TrySdUpgrade(&recovery_pending))
+            JumpToApplication();
+        if (!recovery_pending && Boot_AppIsValid())
+            JumpToApplication();
+        /* 无有效APP或擦写中失败时保持粉灯；处理SD卡后复位重试。 */
+        Boot_LightWaiting();
+        while (1)
+            HAL_Delay(1000U);
+    }
     if (Boot_ConsumeOtaRequest())
     {
         Boot_LightWaiting();
diff --git a/App/Src/app_ws2812.c b/App/Src/app_ws2812.c
index 3f9bddb..64b4871 100644
--- a/App/Src/app_ws2812.c
+++ b/App/Src/app_ws2812.c
@@ -1,6 +1,7 @@
 #include "app_ws2812.h"
 #include "app_board.h"
 #include "tim.h"
+#include "string.h"
 // 预设颜色RGB表
 RGB_t Color_table[] =
     {
@@ -18,6 +19,37 @@ RGB_t Color_table[] =
 void Light_SetAllColor(RGB_t color, uint16_t *buffer)
 {
     uint8_t i, j;
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+    {
+        static const uint8_t Count[2] = {36U, 49U};
+        uint8_t strip, component, mask;
+        uint8_t grb[3] = {color.G, color.R, color.B};
+        for (strip = 0U; strip < 2U; strip++)
+        {
+            uint32_t channel = strip ? TIM_CHANNEL_2 : TIM_CHANNEL_1;
+            uint16_t offset = 1U;
+            uint16_t size = (uint16_t)(1U + Count[strip] * 24U + 256U);
+            /* 中文注释：复用原缓冲，按GRB高位先发；尾部低电平320us锁存。 */
+            memset(buffer, 0, size * sizeof(uint16_t));
+            for (i = 0U; i < Count[strip]; i++)
+                for (component = 0U; component < 3U; component++)
+                    for (mask = 0x80U; mask != 0U; mask >>= 1U)
+                        buffer[offset++] = (grb[component] & mask) ? 10U : 4U;
+            __HAL_TIM_SET_COMPARE(&htim3, channel, 0U);
+            HAL_TIM_PWM_Start(&htim3, channel);
+            HAL_Delay(1U);
+            HAL_TIM_PWM_Stop(&htim3, channel);
+            if (HAL_TIM_PWM_Start_DMA(&htim3, channel, (uint32_t *)buffer, size) == HAL_OK)
+            {
+                /* 最长49颗约1.8ms；等3ms完成后再复用缓冲，不占用其他板型路径。 */
+                HAL_Delay(3U);
+                HAL_TIM_PWM_Stop_DMA(&htim3, channel);
+            }
+            __HAL_TIM_SET_COMPARE(&htim3, channel, 0U);
+            HAL_TIM_PWM_Start(&htim3, channel);
+        }
+        return;
+    }
     for (i = 0; i < Light_RGBbuffer_SIZE; i++)
     {
         for (j = 0; j < 8; j++)
diff --git a/Core/Src/gpio.c b/Core/Src/gpio.c
index e505dc2..beba045 100644
--- a/Core/Src/gpio.c
+++ b/Core/Src/gpio.c
@@ -20,6 +20,7 @@

 /* Includes ------------------------------------------------------------------*/
 #include "gpio.h"
+#include "app_board.h"

 /* USER CODE BEGIN 0 */

@@ -50,6 +51,31 @@ void MX_GPIO_Init(void)
   __HAL_RCC_GPIOA_CLK_ENABLE();
   __HAL_RCC_GPIOB_CLK_ENABLE();

+  if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+  {
+    /* 中文注释：引导阶段只亮灯和读SD，按本机APP的低电平关闭所有执行器。 */
+    __HAL_RCC_GPIOE_CLK_ENABLE();
+    __HAL_RCC_GPIOD_CLK_ENABLE();
+    HAL_GPIO_WritePin(GPIOE, GPIO_PIN_9|GPIO_PIN_11|GPIO_PIN_13|GPIO_PIN_14, GPIO_PIN_RESET);
+    HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13, GPIO_PIN_RESET);
+    HAL_GPIO_WritePin(GPIOC, GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7, GPIO_PIN_RESET);
+    HAL_GPIO_WritePin(GPIOB, GPIO_PIN_3|GPIO_PIN_4, GPIO_PIN_RESET);
+    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_0, GPIO_PIN_RESET);
+    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
+    GPIO_InitStruct.Pull = GPIO_NOPULL;
+    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
+    GPIO_InitStruct.Pin = GPIO_PIN_9|GPIO_PIN_11|GPIO_PIN_13|GPIO_PIN_14;
+    HAL_GPIO_Init(GPIOE, &GPIO_InitStruct);
+    GPIO_InitStruct.Pin = GPIO_PIN_12|GPIO_PIN_13;
+    HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);
+    GPIO_InitStruct.Pin = GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
+    HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
+    GPIO_InitStruct.Pin = GPIO_PIN_3|GPIO_PIN_4;
+    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
+    GPIO_InitStruct.Pin = GPIO_PIN_0;
+    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
+  }
+
   /*Configure GPIO pin Output Level */
   HAL_GPIO_WritePin(LED_GPIO_Port, LED_Pin, GPIO_PIN_RESET);

diff --git a/Core/Src/main.c b/Core/Src/main.c
index 0db3798..a1a2f42 100644
--- a/Core/Src/main.c
+++ b/Core/Src/main.c
@@ -97,7 +97,9 @@ int main(void)
   MX_DMA_Init();
   MX_SPI1_Init();
   MX_FATFS_Init();
-  MX_USART1_UART_Init();
+  /* 中文注释：DIAOQIU仅使用SD卡，不初始化升级/球盘提示串口。 */
+  if (Boot_BoardGetId() != BOOT_BOARD_DIAOQIU)
+    MX_USART1_UART_Init();
   /* 武松和一统天下通过USART2控制各自球盘提示，其他板型保留RGB定时器。 */
   if (Boot_BoardGetId() == BOOT_BOARD_WUSONG || Boot_BoardGetId() == BOOT_BOARD_YITONG)
     MX_USART2_UART_Init();
diff --git a/Core/Src/tim.c b/Core/Src/tim.c
index fdc6067..89f8c9a 100644
--- a/Core/Src/tim.c
+++ b/Core/Src/tim.c
@@ -46,7 +46,8 @@ void MX_TIM3_Init(void)

   /* USER CODE END TIM3_Init 1 */
   htim3.Instance = TIM3;
-  htim3.Init.Prescaler = 5;
+  /* 掉珠机与APP一致：84MHz / (6+1) / (14+1) = 800kHz。 */
+  htim3.Init.Prescaler = Boot_BoardGetId() == BOOT_BOARD_DIAOQIU ? 6U : 5U;
   htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
   htim3.Init.Period = 14;
   htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
@@ -188,7 +189,17 @@ void HAL_TIM_MspPostInit(TIM_HandleTypeDef* timHandle)
      * 弹界/扭蛋：PC9=CH4、PB4=CH1、PB5=CH2。
      * 蟠桃：PC7=CH2、PC9=CH4、PB4=CH1。
      */
-    if (Boot_BoardGetId() == BOOT_BOARD_PANTAO)
+    if (Boot_BoardGetId() == BOOT_BOARD_DIAOQIU)
+    {
+      /* 网表RGB1/2为PC6/PC7，PB4是12V负载控制，不能沿用旧灯效引脚。 */
+      GPIO_InitStruct.Pin = GPIO_PIN_6|GPIO_PIN_7;
+      GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
+      GPIO_InitStruct.Pull = GPIO_NOPULL;
+      GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
+      GPIO_InitStruct.Alternate = GPIO_AF2_TIM3;
+      HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
+    }
+    else if (Boot_BoardGetId() == BOOT_BOARD_PANTAO)
     {
       GPIO_InitStruct.Pin = GPIO_PIN_7|GPIO_PIN_9;
       GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
diff --git a/MDK-ARM/export_firmware.ps1 b/MDK-ARM/export_firmware.ps1
index 118a71e..93bbc02 100644
--- a/MDK-ARM/export_firmware.ps1
+++ b/MDK-ARM/export_firmware.ps1
@@ -26,6 +26,7 @@ try {
         BOOT_BOARD_NIUDAN = 'Bootloader_Niudan'
         BOOT_BOARD_WUSONG = 'Bootloader_Wusong'
         BOOT_BOARD_YITONG = 'Bootloader_Yitong'
+        BOOT_BOARD_DIAOQIU = 'Bootloader_DIAOQIU'
     }
     $exportBoard = $exportSelection[0].Groups['board'].Value
     if (-not $exportNames.ContainsKey($exportBoard)) {
~~~
