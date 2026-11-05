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

同板型重新编译会覆盖该板型的两个导出文件，其他板型的文件保留。
Keil 原有的 `Bootloader_F407/Bootloader_F407.axf/.hex` 输出设置保持不变。
导出目录已加入 `.gitignore`。

## 导出校验与手动执行

脚本只接受上述四种板型，板型选择格式保持为上面的单行赋值。
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
`niudan.bin` 或 `wusong.bin`；APP 起始地址仍为 `0x0800C000`。

## 修改范围和验证步骤

- `MDK-ARM/export_firmware.ps1`：新增导出脚本，读取现有板型选择并校验输出。
- `MDK-ARM/Bootloader_F407.uvprojx`：原编译后命令为空，改为调用该脚本；补列已有的 `app_ws2812.c`，避免非武松板型出现 RGB 符号链接失败，不修改灯效源码。
- `MDK-ARM/.eide/eide.yml`：原两个 AC5 目标的 `afterBuildTasks` 为空，均接入同一脚本。
- `App/Src/app_bootloader.c`：仅更新板型选择旁的导出说明注释，固件逻辑不变。
- `.gitignore`：增加生成目录规则。

依次选择四个板型并执行 Keil Rebuild，检查日志中的 `Exported` 行和四组命名文件。
核对 HEX 校验和、地址及 BIN 内容一致，且 Bootloader 未超出前48KB。
修改板型后不重新编译，单独执行脚本应报错；非法板型、缺失输入或转换失败时
也应返回非零值，并保留已有正式导出文件。EIDE 的两个 AC5 目标需分别回归构建。
本功能只改变编译后的导出，不改变升级协议；烧录和实机运行需另行验证。

## 本次软件验证结果

四种板型均实际通过 Keil 编译及 After Build 自动导出，并从各自 AXF 执行
`Boot_BoardGetId()` 确认返回值与文件名对应：

| 板型 | 编译结果内的Board ID | BIN字节数 |
| --- | --- | --- |
| 弹界 | 1 | 21228 |
| 蟠桃 | 2 | 21228 |
| 扭蛋 | 3 | 21228 |
| 武松 | 4 | 20800 |

四组 HEX 校验和、地址范围及 HEX/BIN 内容一致性检查均通过，四组文件可同时保留。
非法板型、换板型未重编译、缺失AXF、转换失败、误用APP镜像这五种场景均返回非零值，
已有正式输出内容未变。EIDE配置已解析，并按两个目标的变量展开执行了导出命令；
完整EIDE编译流程和实机烧录尚未验证。
