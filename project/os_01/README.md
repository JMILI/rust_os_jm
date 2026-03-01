# os_01 - 独立式 Rust 二进制程序

这是基于教程第一步创建的项目，实现了一个不链接标准库的独立式 Rust 二进制程序。

## 📚 教程对应

- **教程**: [01_独立式Rust二进制程序.md](../../tutorial/src/01_独立式Rust二进制程序.md)
- **参考代码**: `../../ref_code/blog_os` 的 `post-01` 分支
- **原文**: https://os.phil-opp.com/freestanding-rust-binary/

## 🎯 项目目标

创建一个不依赖操作系统的 Rust 程序，这是创建操作系统内核的第一步。

## 📁 项目结构

```
os_01/
├── Cargo.toml      # 项目配置文件
├── src/
│   └── main.rs     # 主程序文件
└── README.md       # 本文件
```

## 🔨 编译

### Linux 系统

```bash
cargo rustc -- -Clink-arg=-nostartfiles
```

### macOS 系统

```bash
cargo rustc -- -Clink-arg=-nostdlib -Clink-arg=-Wl,-e,__start
```

## 📊 代码说明

### 关键特性

- `#![no_std]`: 禁用标准库，只使用核心库（core）
- `#![no_main]`: 禁用标准 main 函数
- `_start()`: 自定义入口点，使用 C 调用约定
- `panic_handler`: 自定义 panic 处理函数

### 代码结构

```rust
#![no_std]
#![no_main]

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

## ✅ 验证

编译成功后，二进制文件位于：
- `target/debug/os_01` (Linux)
- `target/debug/os_01.exe` (Windows)

## 🎓 下一步

完成本教程后，可以继续学习：
- [02_最小Rust内核.md](../../tutorial/src/02_最小Rust内核.md) - 创建可启动的内核

---

**项目状态**: ✅ 已完成并可以编译
