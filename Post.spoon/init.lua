local obj = {}
obj.__index = obj

obj.name = "Post"
obj.version = "1.2.0"
obj.author = "Victor Zhang × Hammerspoon"
obj.license = "MIT"

local STORAGE_KEY = "Post.storagePath"

obj.captureView = nil
obj.isDirty = false
obj.currentPost = nil
obj.handlingClose = false

-- Storage -------------------------------------------------

local CONFIG_PATH = os.getenv("HOME") .. "/.hammerspoon/Post.storage"

local function readStoragePath()
    local file = io.open(CONFIG_PATH, "r")
    if not file then
        return nil
    end

    local path = file:read("*l")
    file:close()

    if not path or path == "" then
        return nil
    end

    return path
end

local function writeStoragePath(path)
    local file = io.open(CONFIG_PATH, "w")
    if not file then
        return false
    end

    file:write(path)
    file:close()
    return true
end

function obj:chooseStoragePath()
    local current = readStoragePath()
    local defaultPath = current or (os.getenv("HOME") .. "/Desktop")

    local selected = hs.dialog.chooseFileOrFolder(
        "选择 Post 的 Markdown 存储文件夹",
        defaultPath,
        false, -- canChooseFiles
        true,  -- canChooseDirectories
        false, -- allowsMultipleSelection
        {},    -- allowedFileTypes
        true   -- resolvesAliases
    )

    if selected then
        local path = selected[1] or selected["1"]

        if path and writeStoragePath(path) then
            return path
        end

        hs.dialog.blockAlert(
            "保存失败",
            "无法保存 Post 的存储目录设置。",
            "确定",
            nil,
            "critical"
        )
    end

    return nil
end

function obj:getStoragePath()
    local path = readStoragePath()

    if path and hs.fs.attributes(path, "mode") == "directory" then
        return path
    end

    return self:chooseStoragePath()
end


-- File helpers --------------------------------------------
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function writeFile(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function appendFile(path, content)
    local f = io.open(path, "a")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function findLastPlain(text, target)
    local start = 1
    local lastStart, lastEnd = nil, nil
    while true do
        local s, e = string.find(text, target, start, true)
        if not s then break end
        lastStart, lastEnd = s, e
        start = e + 1
    end
    return lastStart, lastEnd
end

local function makeBlock(time, text)
    return "## " .. time .. "\n\n" .. text .. "\n\n"
end

-- Save ----------------------------------------------------
function obj:savePost(text)
    if not text or text:match("^%s*$") then return false end

    local dir = self:getStoragePath()
    if not dir then return false end

    if not self.currentPost then
        local date = os.date("%Y-%m-%d")
        local time = os.date("%H:%M")
        local path = dir .. "/" .. date .. ".md"
        local block = makeBlock(time, text)

        local ok
        if hs.fs.attributes(path) then
            ok = appendFile(path, block)
        else
            ok = writeFile(path, "# " .. date .. "\n\n" .. block)
        end

        if not ok then
            hs.dialog.blockAlert("保存失败", "无法写入 Markdown 文件。", "确定", nil, "critical")
            return false
        end

        self.currentPost = { path = path, time = time, block = block }
        return true
    end

    local content = readFile(self.currentPost.path)
    if not content then return false end

    local newBlock = makeBlock(self.currentPost.time, text)
    local s, e = findLastPlain(content, self.currentPost.block)

    if not s then
        hs.dialog.blockAlert(
            "无法更新",
            "当天的 Markdown 文件可能已被其他程序修改。",
            "确定",
            nil,
            "warning"
        )
        return false
    end

    local updated = string.sub(content, 1, s - 1) .. newBlock .. string.sub(content, e + 1)
    if not writeFile(self.currentPost.path, updated) then return false end

    self.currentPost.block = newBlock
    return true
end

-- UI ------------------------------------------------------
local html = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
* { box-sizing: border-box; }
html, body {
    width: 100%; height: 100%; margin: 0; padding: 0;
    background: #1C1C1E; overflow: hidden;
}
body {
    display: flex; flex-direction: column;
    background: #1C1C1E; color: #F5F5F7;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", sans-serif;
}
.titlebar {
    height: 52px; min-height: 52px; display: flex; align-items: center;
    padding-left: 82px; padding-top: 6px;
    background: #242426; border-bottom: 1px solid #3A3A3C;
    color: #F5F5F7; font-size: 15px; font-weight: 600; user-select: none;
}
#post {
    flex: 1; min-height: 0; width: 100%; padding: 28px 36px; overflow-y: auto;
    white-space: pre-wrap; overflow-wrap: anywhere;
    border: none; outline: none; resize: none;
    background: #1C1C1E; color: #F5F5F7;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", sans-serif;
    font-size: 18px; line-height: 1.8; caret-color: #FFFFFF;
}
#post[data-empty="true"]::before { content: "写点什么……"; color: #6E6E73; pointer-events: none; position: absolute; }
#post div, #post p { margin: 0; min-height: 1.8em; }
#post h1, #post h2, #post h3, #post h4, #post h5, #post h6 { margin: 0; line-height: 1.5; font-weight: 650; }
#post h1 { font-size: 1.65em; } #post h2 { font-size: 1.4em; } #post h3 { font-size: 1.2em; }
#post h4, #post h5, #post h6 { font-size: 1.05em; }
#post ul { margin: 0; padding-left: 1.5em; list-style-type: disc; }
#post li { min-height: 1.8em; }
#post li:has(> .task) { list-style-type: none; }
#post .task { cursor: pointer; display: inline-block; margin-left: -1.35em; width: 1.1em; user-select: none; color: #D1D1D6; }
#post blockquote { margin: 0 0 0 1.5em; padding: 0; border: 0; }
#post strong, #post b { font-weight: 700; }
.footer {
    height: 46px; min-height: 46px; display: flex; align-items: center; justify-content: flex-end;
    padding: 0 20px; background: #242426; border-top: 1px solid #3A3A3C;
    color: #8E8E93; font-size: 12px; user-select: none;
}
.key { color: #D1D1D6; }
</style>
</head>
<body>
<div class="titlebar">Post</div>
<div id="post" contenteditable="true" role="textbox" aria-label="记录" aria-multiline="true" data-empty="true" spellcheck="false"></div>
<div class="footer">
    <span class="key">⌘S</span>&nbsp;保存
    &nbsp;&nbsp;·&nbsp;&nbsp;
    <span class="key">⌘W</span>&nbsp;关闭
</div>
<script>
const editor = document.getElementById("post");
let lastSavedValue = "";
let converting = false;
let composing = false;

function escapeHTML(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function inlineHTML(text) {
    return escapeHTML(text).replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>")
        .replace(/(^|[^*])\*([^*\n]+)\*(?!\*)/g, "$1<em>$2</em>");
}

function taskHTML(checked) {
    return '<span class="task" contenteditable="false" role="checkbox" aria-checked="' + checked +
        '" aria-label="任务" data-task="' + checked + '">' + (checked ? "☑" : "☐") + '</span> ';
}

// Only the supported Markdown constructs become editable HTML; all input is escaped.
function markdownHTML(text) {
    const lines = text.replace(/\r\n?/g, "\n").split("\n");
    let index = 0;
    function listMatch(line) { return line.match(/^([ \t]*)([-*]) (.*)$/); }
    function depth(match) { return match[1].replace(/\t/g, "    ").length; }
    function list(indent) {
        let html = "<ul>";
        while (index < lines.length) {
            const match = listMatch(lines[index]);
            if (!match || depth(match) !== indent) break;
            let body = match[3];
            const task = body.match(/^\[([ xX])\](?: |$)/);
            html += '<li data-marker="' + match[2] + '">' +
                (task ? taskHTML(task[1] !== " ") : "") +
                (inlineHTML(task ? body.slice(task[0].length) : body) || "<br>");
            index++;
            while (index < lines.length) {
                const child = listMatch(lines[index]);
                if (!child || depth(child) <= indent) break;
                html += list(depth(child));
            }
            html += "</li>";
        }
        return html + "</ul>";
    }
    let html = "";
    let fenced = false;
    while (index < lines.length) {
        const line = lines[index];
        if (/^\s*```/.test(line)) fenced = !fenced;
        const match = !fenced && listMatch(line);
        if (match) {
            const levels = Math.floor(depth(match) / 4);
            html += "<blockquote>".repeat(levels) + list(depth(match)) + "</blockquote>".repeat(levels);
            continue;
        }
        const heading = !fenced && line.match(/^(#{1,6}) (.*)$/);
        html += heading ? "<h" + heading[1].length + ">" + (inlineHTML(heading[2]) || "<br>") + "</h" + heading[1].length + ">" :
            "<div>" + ((fenced ? escapeHTML(line) : inlineHTML(line)) || "<br>") + "</div>";
        index++;
    }
    return html;
}

function inlineMarkdown(node) {
    if (node.nodeType === Node.TEXT_NODE) return node.data.replace(/\u00a0/g, " ").replace(/\u200b/g, "");
    if (node.nodeType !== Node.ELEMENT_NODE) return "";
    if (node.matches("ul,ol")) return "";
    if (node.matches("[data-task]")) return node.dataset.task === "true" ? "[x]" : "[ ]";
    if (node.tagName === "BR") return "\n";
    const text = Array.from(node.childNodes, inlineMarkdown).join("");
    if (node.matches("b,strong") || /^(bold|[6-9]00)$/.test(node.style.fontWeight)) return text ? "**" + text + "**" : "";
    if (node.matches("i,em") || node.style.fontStyle === "italic") return text ? "*" + text + "*" : "";
    return text;
}

function blockText(node) { return inlineMarkdown(node).replace(/\n$/, ""); }

function getMarkdown(root = editor) {
    function listLines(list, indent) {
        const result = [];
        for (const item of list.children) {
            if (item.matches("ul,ol")) { result.push(...listLines(item, indent + "    ")); continue; }
            if (item.tagName !== "LI") continue;
            const text = Array.from(item.childNodes, node => {
                const value = inlineMarkdown(node);
                return node.nodeType === 1 && node.matches("div,p") ? value + "\n" : value;
            }).join("").replace(/\n$/, "");
            const parts = text.split("\n");
            result.push(indent + (item.dataset.marker || "-") + " " + parts[0]);
            result.push(...parts.slice(1).map(line => indent + "    " + line));
            for (const child of item.children) if (child.matches("ul,ol")) result.push(...listLines(child, indent + "    "));
        }
        return result;
    }
    function blocks(parent, indent = "") {
        const result = [];
        let inline = "";
        function flush() { if (inline) { result.push(indent + inline); inline = ""; } }
        for (const node of parent.childNodes) {
            if (node.nodeType !== 1 || !node.matches("div,p,h1,h2,h3,h4,h5,h6,ul,ol,blockquote")) {
                inline += inlineMarkdown(node); continue;
            }
            flush();
            if (node.matches("ul,ol")) result.push(...listLines(node, indent));
            else if (node.tagName === "BLOCKQUOTE") result.push(...blocks(node, indent + "    "));
            else if (/^H[1-6]$/.test(node.tagName)) result.push(indent + "#".repeat(Number(node.tagName[1])) + " " + blockText(node));
            else if (Array.from(node.children).some(child => child.matches("div,p,ul,ol,blockquote"))) result.push(...blocks(node, indent));
            else result.push(indent + blockText(node));
        }
        flush();
        return result;
    }
    return blocks(root).join("\n").replace(/\n+$/, "");
}

function updateDirtyState() {
    editor.dataset.empty = editor.textContent.replace(/\u200b/g, "") === "" && !editor.querySelector("li,h1,h2,h3,h4,h5,h6");
    window.webkit.messageHandlers.capture.postMessage({ action: "dirty", dirty: getMarkdown() !== lastSavedValue });
}

function currentBlock() {
    const selection = getSelection();
    if (!selection.rangeCount || !editor.contains(selection.anchorNode)) return null;
    const element = selection.anchorNode.nodeType === 1 ? selection.anchorNode : selection.anchorNode.parentElement;
    return element.closest("li,h1,h2,h3,h4,h5,h6,div,p,blockquote") || editor;
}

function command(name, value) {
    const previous = converting;
    converting = true;
    document.execCommand(name, false, value);
    converting = previous;
}

function selectContents(node) {
    const range = document.createRange();
    range.selectNodeContents(node);
    getSelection().removeAllRanges(); getSelection().addRange(range);
}

// Markdown triggers use native editing commands, retaining WebKit's undo history.
function applyMarkdown() {
    const selection = getSelection();
    let block = currentBlock();
    if (!block || !selection.isCollapsed) return;
    // WebKit may leave a bare text node after exiting a list. Normalize only
    // that paragraph so triggers never include the preceding blocks.
    if (block === editor) { command("formatBlock", "div"); block = currentBlock(); }
    const caret = selection.getRangeAt(0);
    const before = caret.cloneRange(); before.selectNodeContents(block); before.setEnd(caret.endContainer, caret.endOffset);
    const prefix = before.toString().replace(/\u00a0/g, " ");
    const marker = prefix.match(/^(#{1,6}|[-*]) $/);
    if (marker && !block.closest("li")) {
        selection.removeAllRanges(); selection.addRange(before);
        command("delete");
        if (marker[1][0] === "#") command("formatBlock", "h" + marker[1].length);
        else {
            command("insertUnorderedList");
            const item = currentBlock();
            if (item && item.tagName === "LI") item.dataset.marker = marker[1];
        }
        return;
    }
    const item = block.closest("li");
    if (item && /^\[([ xX])\] $/.test(prefix) && !item.querySelector(".task")) {
        selection.removeAllRanges(); selection.addRange(before);
        command("insertHTML", taskHTML(prefix[1] !== " "));
        return;
    }
    // Inline triggers only examine the text node being edited, not other paragraphs.
    const node = caret.endContainer;
    if (node.nodeType !== Node.TEXT_NODE || node.parentElement.closest("strong,b,em,i,.task")) return;
    const text = node.data.slice(0, caret.endOffset);
    const bold = text.match(/\*\*([^*\n]+)\*\*$/);
    const italic = !bold && text.match(/(?:^|[^*])(\*([^*\n]+)\*)$/);
    const match = bold || italic;
    if (!match) return;
    const raw = bold ? bold[0] : italic[1];
    const range = document.createRange(); range.setStart(node, caret.endOffset - raw.length); range.setEnd(node, caret.endOffset);
    selection.removeAllRanges(); selection.addRange(range);
    const tag = bold ? "strong" : "em";
    command("insertHTML", "<" + tag + ">" + escapeHTML(bold ? bold[1] : italic[2]) + "</" + tag + ">\u200b");
}

editor.addEventListener("compositionstart", () => { composing = true; });
editor.addEventListener("compositionend", () => { composing = false; applyMarkdown(); updateDirtyState(); });
editor.addEventListener("input", e => {
    if (converting) return;
    if (composing || e.isComposing) { updateDirtyState(); return; }
    if (e.inputType !== "historyUndo" && e.inputType !== "historyRedo") applyMarkdown();
    updateDirtyState();
});
editor.addEventListener("paste", e => {
    e.preventDefault();
    const text = e.clipboardData.getData("text/plain");
    if (/\n|^(?:#{1,6}|[-*]) /.test(text)) command("insertHTML", markdownHTML(text));
    else { command("insertText", text); applyMarkdown(); }
    updateDirtyState();
});
editor.addEventListener("drop", e => { e.preventDefault(); });
editor.addEventListener("click", e => {
    const task = e.target.closest(".task");
    if (!task) return;
    selectContents(task); getSelection().getRangeAt(0).selectNode(task);
    command("insertHTML", taskHTML(task.dataset.task !== "true").trimEnd());
    updateDirtyState();
});
editor.addEventListener("keydown", e => {
    if (composing || e.isComposing || e.keyCode === 229 || e.metaKey || e.ctrlKey || e.altKey) return;
    const block = currentBlock();
    if (!block) return;
    if (e.key === "Tab") {
        e.preventDefault();
        if (!e.shiftKey || block.closest("blockquote") || block.closest("li")?.parentElement.parentElement.closest("li,ul,ol")) command(e.shiftKey ? "outdent" : "indent");
        updateDirtyState();
    } else if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        const item = block.closest("li");
        const task = item && item.querySelector(":scope > .task");
        const marker = item && item.dataset.marker;
        const empty = item && !blockText(item).replace(/^\[[ xX]\]\s*/, "").trim() && !item.querySelector("ul,ol");
        if (empty) {
            if (task) { selectContents(item); command("delete"); }
            for (let level = 0; level < 20 && currentBlock()?.closest("li,blockquote"); level++) command("outdent");
            command("formatBlock", "div");
            command("removeFormat");
        } else {
            command("insertParagraph");
            const next = currentBlock();
            if (item && next?.tagName === "LI") {
                if (marker) next.dataset.marker = marker;
                if (task && !next.querySelector(":scope > .task")) command("insertHTML", taskHTML(false));
            } else if (next && /^H[1-6]$/.test(next.tagName)) command("formatBlock", "div");
        }
        updateDirtyState();
    }
});

window.markSaved = function() { lastSavedValue = getMarkdown(); updateDirtyState(); };
window.resetPost = function() { editor.innerHTML = ""; lastSavedValue = ""; updateDirtyState(); };

document.addEventListener("keydown", e => {
    if (e.metaKey && !e.ctrlKey && e.key.toLowerCase() === "s") {
        e.preventDefault();
        const text = getMarkdown().trimEnd();
        if (text.trim()) window.webkit.messageHandlers.capture.postMessage({ action: "save", text });
    } else if (e.metaKey && !e.ctrlKey && e.key.toLowerCase() === "w") {
        e.preventDefault(); window.webkit.messageHandlers.capture.postMessage({ action: "closeRequest" });
    }
});
document.execCommand("defaultParagraphSeparator", false, "div");
updateDirtyState();
</script>

</body>
</html>
]]

-- State ---------------------------------------------------
function obj:resetCurrentPost()
    self.isDirty = false
    self.currentPost = nil
    if self.captureView then
        -- A fresh document also clears WebKit undo history between records.
        self.captureView:html(html)
    end
end

function obj:focusEditor()
    if not self.captureView then return end

    self.captureView:level(hs.drawing.windowLevels.normal)
    self.captureView:show()

    local win = self.captureView:hswindow()
    if win then win:focus() end

    hs.timer.doAfter(0.1, function()
        if self.captureView then
            self.captureView:evaluateJavaScript([[
                document.getElementById("post").focus();
            ]])
        end
    end)
end

function obj:requestClose()
    if not self.captureView then return end

    if self.isDirty then
        local result = hs.dialog.blockAlert(
            "内容尚未保存",
            "确定关闭并放弃未保存的修改吗？",
            "继续编辑",
            "不保存并关闭",
            "warning"
        )

        if result == "继续编辑" then
            self:focusEditor()
            return
        end
    end

    self.captureView:hide()
    self:resetCurrentPost()
end

-- JS -> Lua ----------------------------------------------
local controller = hs.webview.usercontent.new("capture")

controller:setCallback(function(message)
    local data = message.body

    if data.action == "save" then
        local ok = obj:savePost(data.text)
        if ok then
            obj.isDirty = false
            if obj.captureView then
                obj.captureView:evaluateJavaScript([[
                    if (window.markSaved) { window.markSaved(); }
                ]])
            end
        end
    elseif data.action == "dirty" then
        obj.isDirty = data.dirty == true
    elseif data.action == "closeRequest" then
        obj:requestClose()
    end
end)

-- Window --------------------------------------------------
function obj:createCaptureView()
    local screen = hs.screen.mainScreen():frame()
    local width, height = 700, 460

    local frame = {
        x = screen.x + (screen.w - width) / 2,
        y = screen.y + (screen.h - height) / 2,
        w = width,
        h = height
    }

    self.captureView = hs.webview.new(frame, { privateBrowsing = true }, controller)

    self.captureView
        :allowTextEntry(true)
        :windowStyle({
            "titled",
            "closable",
            "miniaturizable",
            "resizable",
            "fullSizeContentView"
        })
        :shadow(true)
        :deleteOnClose(false)
        :transparent(false)
        :html(html)

    self.captureView:titleVisibility("hidden")
    self.captureView:darkMode(true)

    self.captureView:windowCallback(function(action, webview)
        if action ~= "closing" then return end
        if self.handlingClose then return end

        if not self.isDirty then
            self:resetCurrentPost()
            return
        end

        self.handlingClose = true

        hs.timer.doAfter(0.05, function()
            local result = hs.dialog.blockAlert(
                "内容尚未保存",
                "确定关闭并放弃未保存的修改吗？",
                "继续编辑",
                "不保存并关闭",
                "warning"
            )

            if result == "继续编辑" then
                self:focusEditor()
            else
                self:resetCurrentPost()
            end

            self.handlingClose = false
        end)
    end)
end

-- Public --------------------------------------------------
function obj:show()
    local dir = self:getStoragePath()

    if not dir then
        return
    end

    if not self.captureView then
        self:createCaptureView()
    end

    self:focusEditor()
end

function obj:bindHotkeys(mapping)
    hs.spoons.bindHotkeysToSpec({
        show = hs.fnutils.partial(self.show, self)
    }, mapping)
    return self
end

return obj
