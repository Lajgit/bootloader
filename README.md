# 通用Bootloader编译与固件命名

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

同板型重新编译会覆盖该板型的两个导出文件，其他板型的文件保留。
Keil 原有的 `Bootloader_F407/Bootloader_F407.axf/.hex` 输出设置保持不变。
导出目录已加入 `.gitignore`。

## 导出校验与手动执行

脚本只接受上述五种板型，板型选择格式保持为上面的单行赋值。
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
