# 05. CPU 异常

> **原文**：https://os.phil-opp.com/cpu-exceptions/  
> **参考代码分支**：post-05  
> **难度**：⭐⭐⭐⭐☆

---

## 📚 教程目标

CPU 异常在各种错误情况下发生，例如访问无效内存地址或除以零时。为了响应它们，我们必须设置一个提供处理函数的*中断描述符表*。在本教程结束时，我们的内核将能够捕获断点异常并在之后恢复正常执行。

在本教程结束时，您将：
- 理解 CPU 异常的概念
- 设置中断描述符表（IDT）
- 实现异常处理程序
- 处理断点异常

---

## 🎯 概述

CPU 异常是 CPU 在执行指令时遇到的特殊情况，例如：
- **页错误**：访问无效内存地址
- **除零错误**：除以零
- **断点**：调试断点
- **一般保护错误**：违反内存保护规则

为了处理这些异常，我们需要：
1. 创建中断描述符表（IDT）
2. 为每个异常注册处理函数
3. 实现处理函数来响应异常

---

## 📝 实现步骤

### 步骤 1：安装 x86_64 crate

在 `Cargo.toml` 中添加：

```toml
[dependencies]
x86_64 = "0.14"
```

### 步骤 2：创建中断模块

创建 `src/interrupts.rs`：

```rust
use x86_64::structures::idt::{InterruptDescriptorTable, InterruptStackFrame};

static mut IDT: InterruptDescriptorTable = InterruptDescriptorTable::new();

pub fn init_idt() {
    unsafe {
        IDT.breakpoint.set_handler_fn(breakpoint_handler);
        IDT.load();
    }
}

extern "x86-interrupt" fn breakpoint_handler(
    stack_frame: InterruptStackFrame
) {
    println!("EXCEPTION: BREAKPOINT\n{:#?}", stack_frame);
}
```

### 步骤 3：更新 main.rs

```rust
mod interrupts;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    println!("Hello World{}", "!");

    blog_os::init();

    // 触发断点异常
    x86_64::instructions::interrupts::int3();

    println!("It did not crash!");
    loop {}
}
```

---

## 🔍 关键概念

### 1. 中断描述符表（IDT）

IDT 是一个包含异常处理程序地址的表。当异常发生时，CPU 会查找 IDT 并跳转到相应的处理函数。

### 2. 中断栈帧

当异常发生时，CPU 会推送一个中断栈帧，包含：
- 指令指针
- 代码段选择器
- CPU 标志
- 堆栈指针
- 堆栈段选择器

### 3. 异常类型

x86_64 架构定义了多种异常类型，每种都有特定的用途。

---

## 🎓 下一步

现在您已经实现了基本的异常处理。在下一个教程中，我们将：
- 处理双重错误异常
- 设置中断堆栈表
- 防止三重错误

---

## 📚 参考资源

- **原文**：https://os.phil-opp.com/cpu-exceptions/
- **参考代码**：`../ref_code/blog_os` 的 `post-05` 分支

---

**教程完成！** ✅ 您现在可以继续学习下一个教程：[06_双重错误.md](06_双重错误.md)
