#![no_std]  // 禁用标准库
#![no_main] // 禁用标准 main 函数

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
