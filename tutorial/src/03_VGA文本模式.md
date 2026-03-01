# 03. VGA 文本模式

> **原文**：https://os.phil-opp.com/vga-text-mode/  
> **参考代码分支**：post-03  
> **难度**：⭐⭐⭐☆☆

---

## 📚 教程目标

VGA 文本模式是一种在屏幕上打印文本的简单方法。在本教程中，我们创建一个接口，通过将所有不安全的操作封装在一个单独的模块中，使其使用安全且简单。我们还实现了对 Rust 格式化宏的支持。

在本教程结束时，您将：
- 创建一个安全的 VGA 文本模式接口
- 实现 `Writer` 结构体来封装 VGA 缓冲区操作
- 实现 `Write` trait 以支持格式化宏
- 使用 `println!` 宏来打印文本

---

## 🎯 概述

在前一个教程中，我们直接操作 VGA 缓冲区，这是不安全的。现在我们将：
1. 创建一个 `Writer` 结构体来封装缓冲区操作
2. 实现 `Write` trait 以支持格式化
3. 实现 `println!` 宏
4. 处理换行和滚动

---

## 📝 实现步骤

### 步骤 1：创建 VGA 缓冲区模块

创建 `src/vga_buffer.rs`：

```rust
use volatile::Volatile;
use core::fmt;

/// VGA 文本缓冲区的颜色
#[allow(dead_code)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Color {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

/// 颜色代码（前景色 + 背景色）
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(transparent)]
struct ColorCode(u8);

impl ColorCode {
    fn new(foreground: Color, background: Color) -> ColorCode {
        ColorCode((background as u8) << 4 | (foreground as u8))
    }
}

/// 屏幕字符（ASCII 字符 + 颜色代码）
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)]
struct ScreenChar {
    ascii_character: u8,
    color_code: ColorCode,
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

/// VGA 文本缓冲区
#[repr(transparent)]
struct Buffer {
    chars: [[Volatile<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT],
}

/// VGA 文本模式写入器
pub struct Writer {
    column_position: usize,
    color_code: ColorCode,
    buffer: &'static mut Buffer,
}

impl Writer {
    /// 创建新的写入器
    pub fn new(foreground: Color, background: Color) -> Writer {
        Writer {
            column_position: 0,
            color_code: ColorCode::new(foreground, background),
            buffer: unsafe { &mut *(0xb8000 as *mut Buffer) },
        }
    }

    /// 写入单个字节
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            byte => {
                if self.column_position >= BUFFER_WIDTH {
                    self.new_line();
                }

                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;

                let color_code = self.color_code;
                self.buffer.chars[row][col].write(ScreenChar {
                    ascii_character: byte,
                    color_code,
                });
                self.column_position += 1;
            }
        }
    }

    /// 写入字符串
    pub fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                // 可打印 ASCII 字符或换行符
                0x20..=0x7e | b'\n' => self.write_byte(byte),
                // 不支持其他字符，打印 `■`
                _ => self.write_byte(0xfe),
            }
        }
    }

    /// 换行
    fn new_line(&mut self) {
        // 将所有行向上移动一行
        for row in 1..BUFFER_HEIGHT {
            for col in 0..BUFFER_WIDTH {
                let character = self.buffer.chars[row][col].read();
                self.buffer.chars[row - 1][col].write(character);
            }
        }
        // 清空最后一行
        self.clear_row(BUFFER_HEIGHT - 1);
        self.column_position = 0;
    }

    /// 清空指定行
    fn clear_row(&mut self, row: usize) {
        let blank = ScreenChar {
            ascii_character: b' ',
            color_code: self.color_code,
        };
        for col in 0..BUFFER_WIDTH {
            self.buffer.chars[row][col].write(blank);
        }
    }
}

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.write_string(s);
        Ok(())
    }
}
```

### 步骤 2：添加 volatile 依赖

在 `Cargo.toml` 中添加：

```toml
[dependencies]
bootloader = "0.9"
volatile = "0.4"
```

### 步骤 3：实现全局 Writer

在 `src/vga_buffer.rs` 中添加：

```rust
use lazy_static::lazy_static;
use spin::Mutex;

lazy_static! {
    pub static ref WRITER: Mutex<Writer> = Mutex::new(Writer::new(
        Color::Yellow,
        Color::Black,
    ));
}
```

添加依赖：

```toml
[dependencies]
bootloader = "0.9"
volatile = "0.4"
lazy_static = { version = "1.4.0", features = ["spin_no_std"] }
spin = "0.9"
```

### 步骤 4：实现 println! 宏

在 `src/vga_buffer.rs` 中添加：

```rust
#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::vga_buffer::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    WRITER.lock().write_fmt(args).unwrap();
}
```

### 步骤 5：更新 main.rs

```rust
#![no_std]
#![no_main]

mod vga_buffer;

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    use blog_os::println;
    
    println!("Hello World{}", "!");
    println!("This is a test of the VGA text mode.");

    loop {}
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    use blog_os::println;
    println!("{}", info);
    loop {}
}
```

---

## 🔍 关键概念

### 1. Volatile 访问

使用 `volatile` crate 来确保编译器不会优化掉对 VGA 缓冲区的写入。

### 2. 静态可变性

使用 `lazy_static` 和 `spin::Mutex` 来创建线程安全的全局 Writer。

### 3. 格式化宏

实现 `Write` trait 以支持 Rust 的格式化宏（`println!`, `print!`）。

---

## 🎓 下一步

现在您已经创建了一个安全的 VGA 文本模式接口。在下一个教程中，我们将：
- 实现单元测试和集成测试
- 使用 QEMU 来运行测试
- 设置测试框架

---

## 📚 参考资源

- **原文**：https://os.phil-opp.com/vga-text-mode/
- **参考代码**：`../ref_code/blog_os` 的 `post-03` 分支
- **volatile crate**：https://docs.rs/volatile/

---

**教程完成！** ✅ 您现在可以继续学习下一个教程：[04_测试.md](04_测试.md)
