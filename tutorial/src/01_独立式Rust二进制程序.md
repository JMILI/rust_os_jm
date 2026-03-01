# 01. 独立式 Rust 二进制程序

> **原文**：https://os.phil-opp.com/freestanding-rust-binary/  
> **参考代码分支**：post-01  
> **难度**：⭐⭐☆☆☆

---

## 📚 教程目标

创建操作系统内核的第一步是创建一个不链接标准库的 Rust 可执行文件。这使得可以在裸机上运行 Rust 代码，而无需底层操作系统。

在本教程结束时，您将：
- 理解为什么需要禁用标准库
- 创建一个不依赖操作系统的 Rust 程序
- 了解 `no_std` 和 `no_main` 属性的作用
- 实现自定义的 panic 处理程序

---

## 🎯 为什么需要独立式二进制程序？

标准 Rust 二进制程序依赖于操作系统，它们需要：
- **运行时系统**：提供堆栈、线程、异常处理等
- **标准库**：提供文件系统、网络、堆分配等功能
- **C 运行时**：提供程序入口点（`main` 函数）

操作系统内核不能依赖这些，因为它本身就是这些功能的基础。我们需要创建一个**独立式（freestanding）**二进制程序，它不链接任何操作系统库。

---

## 🔧 禁用标准库

在 Rust 中，我们可以使用 `#![no_std]` 属性来禁用标准库：

```rust
#![no_std]

fn main() {
    println!("Hello, world!");
}
```

但是，这段代码还无法编译，因为：
1. `println!` 宏需要标准库
2. `main` 函数需要运行时系统

---

## 📝 创建独立式二进制程序

### 步骤 1：创建新项目

```bash
cargo new blog_os --name blog_os
cd blog_os
```

### 步骤 2：配置 Cargo.toml

编辑 `Cargo.toml` 文件：

```toml
[package]
name = "blog_os"
version = "0.1.0"
authors = ["Your Name <your.email@example.com>"]
edition = "2021"

[dependencies]

[profile.dev]
panic = "abort"

[profile.release]
panic = "abort"
```

**说明**：
- `panic = "abort"`：禁用堆栈展开，因为我们无法在裸机上使用它

### 步骤 3：禁用标准库

在 `src/main.rs` 文件开头添加：

```rust
#![no_std]  // 禁用标准库
#![no_main] // 禁用标准 main 函数

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
```

**代码说明**：
- `#![no_std]`：禁用标准库，只使用核心库（core）
- `#![no_main]`：禁用标准 main 函数，我们将使用自定义入口点
- `#[unsafe(no_mangle)]`：防止 Rust 编译器修改函数名
- `pub extern "C" fn _start()`：使用 C 调用约定，这是链接器期望的入口点
- `-> !`：表示函数永不返回（diverging function）
- `#[panic_handler]`：定义 panic 时的处理函数

---

## 🔨 编译独立式二进制程序

### Linux 系统

```bash
cargo rustc -- -Clink-arg=-nostartfiles
```

### macOS 系统

```bash
cargo rustc -- -Clink-arg=-nostdlib -Clink-arg=-Wl,-e,__start
```

### Windows 系统

需要更复杂的配置，建议使用 Linux 或 WSL 环境。

---

## 📊 代码结构

完整的 `src/main.rs` 文件：

```rust
#![no_std]
#![no_main]

use core::panic::PanicInfo;

/// 这是程序的入口点
/// 链接器期望找到名为 `_start` 的函数
#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    // 由于这是一个独立式程序，我们无法使用标准库
    // 目前只能进入无限循环
    loop {}
}

/// 当程序 panic 时调用此函数
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // 目前我们无法打印任何信息，只能进入无限循环
    loop {}
}
```

---

## 🧪 验证编译

运行编译命令后，应该能够成功编译：

```bash
$ cargo rustc -- -Clink-arg=-nostartfiles
   Compiling blog_os v0.1.0 (/path/to/blog_os)
    Finished dev [unoptimized + debuginfo] target(s) in 0.xxs
```

编译成功后，您可以在 `target/debug/` 目录下找到编译后的二进制文件。

---

## 💡 关键概念

### 1. `no_std` vs `std`

- **`std`**：标准库，提供高级抽象，但需要操作系统支持
- **`no_std`**：只使用核心库（core），不依赖操作系统

### 2. 入口点

- **标准程序**：使用 `main` 函数作为入口点
- **独立式程序**：使用 `_start` 函数作为入口点

### 3. Panic 处理

- **标准程序**：panic 时会打印堆栈跟踪并退出
- **独立式程序**：需要自定义 panic 处理程序

---

## ⚠️ 常见问题

### Q1: 为什么需要 `no_main`？

A: 标准 `main` 函数需要运行时系统来初始化。在裸机上，我们需要直接使用链接器期望的入口点 `_start`。

### Q2: 为什么 `_start` 函数返回 `!`？

A: `!` 表示发散函数（diverging function），即函数永远不会返回。在操作系统内核中，入口点应该永远运行，不应该返回。

### Q3: 为什么 panic handler 也返回 `!`？

A: panic 处理程序应该终止程序或进入无限循环，不应该返回。

---

## 🎓 下一步

现在您已经创建了一个独立式 Rust 二进制程序。在下一个教程中，我们将：
- 创建一个可启动的内核
- 在屏幕上打印 "Hello World!"
- 使用 bootloader 来启动我们的内核

---

## 📚 参考资源

- **原文**：https://os.phil-opp.com/freestanding-rust-binary/
- **参考代码**：`../ref_code/blog_os` 的 `post-01` 分支
- **Rust 核心库文档**：https://doc.rust-lang.org/core/

---

**教程完成！** ✅ 您现在可以继续学习下一个教程：[02_最小Rust内核.md](02_最小Rust内核.md)
