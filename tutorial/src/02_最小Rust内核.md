# 02. 最小 Rust 内核

> **原文**：https://os.phil-opp.com/minimal-rust-kernel/  
> **参考代码分支**：post-02  
> **难度**：⭐⭐⭐☆☆

---

## 📚 教程目标

在本教程中，我们为 x86 架构创建一个最小的 64 位 Rust 内核。我们基于前一个教程的独立式 Rust 二进制程序，创建一个可启动的磁盘镜像，能够在屏幕上打印内容。

在本教程结束时，您将：
- 了解如何创建可启动的内核
- 使用 bootloader crate 来启动内核
- 在 VGA 文本缓冲区中写入数据
- 创建一个可启动的磁盘镜像

---

## 🎯 概述

要创建一个可启动的内核，我们需要：
1. **编译目标**：使用 `x86_64-unknown-none` 目标（裸机目标）
2. **Bootloader**：使用 `bootloader` crate 来处理启动过程
3. **入口点**：定义内核的入口点
4. **VGA 输出**：直接写入 VGA 文本缓冲区来显示文本

---

## 🔧 设置编译目标

### 步骤 1：安装目标

```bash
rustup target add x86_64-unknown-none
```

### 步骤 2：安装 LLVM 工具

```bash
rustup component add llvm-tools-preview
```

### 步骤 3：安装 bootimage

```bash
cargo install bootimage
```

---

## 📝 创建最小内核

### 步骤 1：更新 Cargo.toml

```toml
[package]
name = "blog_os"
version = "0.1.0"
authors = ["Your Name <your.email@example.com>"]
edition = "2021"

[dependencies]
bootloader = "0.9"

[[bin]]
name = "blog_os"
test = false
bench = false

[profile.dev]
panic = "abort"

[profile.release]
panic = "abort"
```

### 步骤 2：创建 rust-toolchain 文件

在项目根目录创建 `rust-toolchain` 文件：

```
nightly
```

这确保项目始终使用 nightly 工具链。

### 步骤 3：创建自定义目标文件

创建 `x86_64-blog_os.json` 文件：

```json
{
    "llvm-target": "x86_64-unknown-none",
    "data-layout": "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128",
    "arch": "x86_64",
    "target-endian": "little",
    "target-pointer-width": "64",
    "target-c-int-width": "32",
    "os": "none",
    "executables": true,
    "linker-flavor": "ld.lld",
    "linker": "rust-lld",
    "panic-strategy": "abort",
    "disable-redzone": true,
    "features": "-mmx,-sse,+soft-float"
}
```

### 步骤 4：编写内核代码

创建 `src/main.rs`：

```rust
#![no_std]
#![no_main]

use core::panic::PanicInfo;

static HELLO: &[u8] = b"Hello World!";

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    // VGA 文本缓冲区的地址是 0xb8000
    let vga_buffer = 0xb8000 as *mut u8;

    // 写入 "Hello World!" 到 VGA 缓冲区
    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0xb; // 浅青色
        }
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
```

**代码说明**：
- `0xb8000`：VGA 文本缓冲区的物理地址
- 每个字符占用 2 字节：1 字节字符 + 1 字节颜色属性
- `0xb`：颜色属性（浅青色背景，黑色前景）

---

## 🚀 构建和运行

### 构建内核

```bash
cargo build --target x86_64-blog_os.json
```

### 创建可启动镜像

```bash
cargo bootimage --target x86_64-blog_os.json
```

### 运行内核（需要 QEMU）

```bash
cargo run --target x86_64-blog_os.json
```

或者直接使用 QEMU：

```bash
qemu-system-x86_64 -drive format=raw,file=target/x86_64-blog_os/debug/bootimage-blog_os.bin
```

---

## 📊 VGA 文本缓冲区

VGA 文本缓冲区是一个内存映射的 I/O 区域，位于物理地址 `0xb8000`。

### 缓冲区布局

- **大小**：25 行 × 80 列 = 2000 个字符
- **每个字符**：2 字节
  - 字节 0：ASCII 字符
  - 字节 1：颜色属性

### 颜色属性格式

```
Bit:    7    6 5 4    3    2 1 0
       Blink  Bg      Intensity  Fg
```

- **前景色（Fg）**：位 0-2
- **背景色（Bg）**：位 4-6
- **高亮（Intensity）**：位 3
- **闪烁（Blink）**：位 7

### 常见颜色值

- `0x0`：黑色
- `0x1`：蓝色
- `0x2`：绿色
- `0x3`：青色
- `0x4`：红色
- `0x5`：品红
- `0x6`：棕色
- `0x7`：浅灰色
- `0x8`：深灰色
- `0x9`：浅蓝色
- `0xa`：浅绿色
- `0xb`：浅青色
- `0xc`：浅红色
- `0xd`：浅品红
- `0xe`：黄色
- `0xf`：白色

---

## 🔍 代码详解

### 入口点 `_start`

```rust
#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    // ...
}
```

- `#[unsafe(no_mangle)]`：防止编译器修改函数名
- `extern "C"`：使用 C 调用约定
- `-> !`：函数永不返回

### VGA 缓冲区写入

```rust
let vga_buffer = 0xb8000 as *mut u8;

for (i, &byte) in HELLO.iter().enumerate() {
    unsafe {
        *vga_buffer.offset(i as isize * 2) = byte;
        *vga_buffer.offset(i as isize * 2 + 1) = 0xb;
    }
}
```

- 将整数地址转换为原始指针
- 使用 `offset` 计算每个字符的位置
- 每个字符占用 2 字节（字符 + 颜色）

---

## ⚠️ 安全问题

直接操作原始指针是**不安全**的，因为：
1. 可能访问无效内存
2. 可能与其他代码产生数据竞争
3. 没有边界检查

在下一个教程中，我们将创建一个安全的 VGA 文本模式接口来封装这些不安全操作。

---

## 🧪 测试

运行内核后，您应该看到：
- QEMU 窗口打开
- 屏幕上显示 "Hello World!"（浅青色背景）

如果看到空白屏幕或错误，请检查：
1. QEMU 是否正确安装
2. bootimage 是否正确安装
3. 编译目标是否正确

---

## 💡 关键概念

### 1. Bootloader

Bootloader 负责：
- 初始化 CPU
- 加载内核到内存
- 设置基本环境
- 跳转到内核入口点

### 2. 内存映射 I/O

VGA 文本缓冲区是内存映射的 I/O，意味着：
- 写入特定内存地址 = 写入屏幕
- 不需要特殊的 I/O 指令

### 3. 裸机目标

`x86_64-unknown-none` 目标表示：
- `x86_64`：64 位 x86 架构
- `unknown`：未知供应商
- `none`：无操作系统

---

## 🎓 下一步

现在您已经创建了一个最小内核并能在屏幕上显示文本。在下一个教程中，我们将：
- 创建一个安全的 VGA 文本模式接口
- 实现 Rust 的格式化宏（`println!`）
- 封装所有不安全的操作

---

## 📚 参考资源

- **原文**：https://os.phil-opp.com/minimal-rust-kernel/
- **参考代码**：`../ref_code/blog_os` 的 `post-02` 分支
- **bootloader crate**：https://docs.rs/bootloader/
- **QEMU 文档**：https://www.qemu.org/documentation/

---

**教程完成！** ✅ 您现在可以继续学习下一个教程：[03_VGA文本模式.md](03_VGA文本模式.md)
