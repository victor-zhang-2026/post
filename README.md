# Post — Local Markdown Daily Notes for macOS

**一键打开、按天沉淀、存储在本地的 macOS Markdown 快速记录工具。**

**A fast, local-first Markdown daily note tool for macOS.**

[Victor Zhang](https://github.com/victor-zhang-2026) × [Hammerspoon](https://www.hammerspoon.org/) · v1.2.0

---

## 中文

Post 让你随时唤起一个轻量输入窗口，把当天的想法快速保存为本地 Markdown。首次使用时选择存储目录；同一天的所有记录都会写入同一个 Markdown 文件，数据始终由你掌控。

这些 Markdown 文件还可以交给任意 Agent 工具继续分析、汇总和洞察。

### 安装

1. 安装 [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/releases)。
2. 下载并解压 `Post-v1.2.0.zip`。
3. 双击 `Install Post.command`。
4. 按 `⌥D`，首次打开时选择 Markdown 存储目录。

### 快捷键

- `⌥D` — 打开
- `⌘S` — 保存
- `⌘W` — 关闭

### Markdown 编辑

在同一个编辑区内输入 Markdown，直接看到对应样式；本地文件仍保存 Markdown 源文本。

- 行首输入 `- ` 或 `* `（符号后加空格），立即显示圆点项目符号。
- 行首输入 `# ` / `## `，立即进入一级 / 二级标题样式；标题末尾 Enter 返回正文。
- 输入 `**重点**` 显示加粗；`*斜体*` 显示斜体。
- 输入 `- [ ] ` 显示任务方框，可点击勾选，保存为 `- [x]`。
- 列表或任务中 Enter 自动续写；空列表项 Enter 退出列表。
- Tab / Shift+Tab 增加 / 减少缩进，保存时每级使用 4 个空格；首级列表反缩进保持项目符号。
- 支持原生撤销与重做；新记录不会通过撤销恢复上一条记录。

窗口布局、打开/保存/关闭快捷键、未保存提醒和每天一个本地 Markdown 文件的方式保持不变。无额外依赖。

验收步骤与结果见 [本机验收清单](LOCAL-ACCEPTANCE.md)。本地检查：`node --test tests/editor.test.cjs`；真实 WebKit 检查脚本：`tests/editor-webkit.js`。

## English

Post opens a lightweight capture window whenever you need it and saves your thoughts as local Markdown. Choose a storage folder on first launch; every entry from the same day is written to one Markdown file, keeping your data fully under your control.

You can later use any Agent tool to analyze, summarize, and uncover insights from these Markdown files.

### Install

1. Install [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/releases).
2. Download and unzip `Post-v1.2.0.zip`.
3. Double-click `Install Post.command`.
4. Press `⌥D` and choose your Markdown storage folder on first launch.

### Shortcuts

- `⌥D` — Open
- `⌘S` — Save
- `⌘W` — Close

### Markdown editing

Type Markdown and see its formatting directly in the same editing area. Local files remain Markdown source.

- Start a line with `- ` or `* ` to create a visible bullet.
- Start with `# ` or `## ` for headings; Enter at the end returns to body text.
- `**emphasis**` becomes bold; `*italic*` becomes italic.
- `- [ ] ` creates a clickable task checkbox, saved as `- [x]` when checked.
- Enter continues bullets/tasks; Enter on an empty item exits the list.
- Tab / Shift+Tab indent/outdent, serialized as four spaces per level.
- Native undo/redo is supported. Each new record starts with fresh undo history.

The window layout, shortcuts, unsaved-change prompts and local daily aggregation remain unchanged. No new dependencies.

## Built together

Post is created by [Victor Zhang](https://github.com/victor-zhang-2026) and powered by [Hammerspoon](https://www.hammerspoon.org/), the open-source macOS automation platform that makes its native shortcuts, window, and local workflow possible.

## License

[MIT](LICENSE)
