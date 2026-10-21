# Post — Local Markdown Daily Notes for macOS

**一键打开、按天沉淀、存储在本地的 macOS Markdown 快速记录工具。**

**A fast, local-first Markdown daily note tool for macOS.**

[Victor Zhang](https://github.com/victor-zhang-2026) × [Hammerspoon](https://www.hammerspoon.org/) · v1.1.0

---

## 中文

Post 让你随时唤起一个轻量输入窗口，把当天的想法快速保存为本地 Markdown。首次使用时选择存储目录；同一天的所有记录都会写入同一个 Markdown 文件，数据始终由你掌控。

这些 Markdown 文件还可以交给任意 Agent 工具继续分析、汇总和洞察。

### 安装

1. 安装 [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/releases)。
2. 下载并解压 `Post-v1.1.0.zip`。
3. 双击 `Install Post.command`。
4. 按 `⌥D`，首次打开时选择 Markdown 存储目录。

### 快捷键

- `⌥D` — 打开
- `⌘S` — 保存
- `⌘W` — 关闭

### Markdown 编辑

保留原来的单一输入框，直接输入 `# 标题`、`- 项目`、`* 项目`、`- [ ] 任务` 和 `**重点**`，以原始 Markdown 文本保存。

- 列表项末尾按 Enter，自动续写相同的 `-` 或 `*` 项目符号，并保留缩进。
- 任务项末尾按 Enter，自动续写未勾选的任务项，例如 `- [ ] `。
- 空列表项再按 Enter，移除项目符号和缩进，回到普通空行。
- Tab 为当前行增加 4 个空格缩进；Shift+Tab 移除最多 4 个前导空格或一个 Tab。
- Shift+Enter 普通换行；自动续写和缩进支持 `⌘Z` 撤销。

原有打开、保存、关闭快捷键、未保存提醒及每天一个本地 Markdown 文件的汇总方式保持不变。

## English

Post opens a lightweight capture window whenever you need it and saves your thoughts as local Markdown. Choose a storage folder on first launch; every entry from the same day is written to one Markdown file, keeping your data fully under your control.

You can later use any Agent tool to analyze, summarize, and uncover insights from these Markdown files.

### Install

1. Install [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/releases).
2. Download and unzip `Post-v1.1.0.zip`.
3. Double-click `Install Post.command`.
4. Press `⌥D` and choose your Markdown storage folder on first launch.

### Shortcuts

- `⌥D` — Open
- `⌘S` — Save
- `⌘W` — Close

### Markdown editing

Keep writing in the same single text area: `# headings`, `- bullets`, `* bullets`, `- [ ] tasks`, and `**emphasis**` are saved as raw Markdown.

- Enter continues the same `-` or `*` bullet and preserves its indentation.
- Enter after a task creates an unchecked task, such as `- [ ] `.
- Enter on an empty list item removes its marker and indentation, returning to a plain blank line.
- Tab indents the current line by four spaces; Shift+Tab removes up to four leading spaces or one tab.
- Shift+Enter inserts a plain line break. Automatic list continuation and indentation support `⌘Z` undo.

Existing shortcuts, unsaved-change prompts, and local daily Markdown aggregation remain unchanged.

## Built together

Post is created by [Victor Zhang](https://github.com/victor-zhang-2026) and powered by [Hammerspoon](https://www.hammerspoon.org/), the open-source macOS automation platform that makes its native shortcuts, window, and local workflow possible.

## License

[MIT](LICENSE)
