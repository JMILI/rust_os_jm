# Writing an OS in Rust - 中文教程 (mdbook)

这是基于 [os.phil-opp.com](https://os.phil-opp.com/) 官方文档的中文教程，使用 mdbook 构建为在线书籍。

## 📚 查看教程

### 方式一：本地构建并查看

1. **构建网站**：
   ```bash
   cd tutorial
   mdbook build
   ```

2. **启动本地服务器**：
   ```bash
   mdbook serve
   ```
   然后在浏览器中打开 http://localhost:3000

### 方式二：直接查看构建结果

构建后的 HTML 文件位于 `tutorial/book/` 目录，可以直接用浏览器打开 `book/index.html`。

## 🛠️ 开发

### 安装 mdbook

如果还没有安装 mdbook：

```bash
cargo install mdbook
```

### 编辑内容

- 所有 Markdown 源文件位于 `src/` 目录
- `Book.toml` 是 mdbook 的配置文件
- `src/SUMMARY.md` 定义了书籍的目录结构

### 实时预览

在编辑时，可以使用以下命令实时预览更改：

```bash
mdbook serve --open
```

这会在浏览器中自动打开并实时更新内容。

## 📁 目录结构

```
tutorial/
├── Book.toml              # mdbook 配置文件
├── README.md              # 本文件
├── src/                   # 源文件目录
│   ├── SUMMARY.md         # 目录结构
│   ├── 00_教程索引.md     # 教程索引
│   ├── 01_独立式Rust二进制程序.md
│   ├── 02_最小Rust内核.md
│   ├── ...
│   └── 附录_参考资源.md
└── book/                  # 构建输出目录（自动生成）
```

## 🔧 配置说明

`Book.toml` 中的主要配置：

- **主题**：使用 `navy` 主题（深蓝色）
- **搜索功能**：已启用全文搜索
- **数学公式**：支持 MathJax
- **编辑链接**：指向原始 GitHub 仓库

## 📝 更新内容

1. 编辑 `src/` 目录下的 Markdown 文件
2. 运行 `mdbook build` 重新构建
3. 运行 `mdbook serve` 查看效果

## 🌐 部署

### GitHub Pages

可以将 `book/` 目录的内容部署到 GitHub Pages：

```bash
# 构建
mdbook build

# 将 book/ 目录的内容推送到 gh-pages 分支
```

### 其他静态网站托管

`book/` 目录包含完整的静态网站，可以部署到任何静态网站托管服务：
- Netlify
- Vercel
- 自己的服务器

## 📖 教程内容

本教程包含以下部分：

1. **Bare Bones（基础骨架）** - 4 个教程
2. **Interrupts（中断）** - 3 个教程
3. **Memory Management（内存管理）** - 4 个教程
4. **Multitasking（多任务处理）** - 1 个教程

## 🔗 相关链接

- **官方英文教程**：https://os.phil-opp.com/
- **GitHub 仓库**：https://github.com/phil-opp/blog_os
- **mdbook 文档**：https://rust-lang.github.io/mdBook/

---

**祝您学习愉快！** 🚀
