local obj = {}
obj.__index = obj

obj.name = "Post"
obj.version = "1.0.0"
obj.author = "Victor"
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
textarea {
    flex: 1; width: 100%; padding: 28px 36px;
    border: none; outline: none; resize: none;
    background: #1C1C1E; color: #F5F5F7;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", sans-serif;
    font-size: 18px; line-height: 1.8; caret-color: #FFFFFF;
}
textarea::placeholder { color: #6E6E73; opacity: 1; }
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
<textarea id="post" placeholder="写点什么……" autofocus spellcheck="false"></textarea>
<div class="footer">
    <span class="key">⌘S</span>&nbsp;保存
    &nbsp;&nbsp;·&nbsp;&nbsp;
    <span class="key">⌘W</span>&nbsp;关闭
</div>
<script>
const textarea = document.getElementById("post");
let lastSavedValue = "";

function updateDirtyState() {
    window.webkit.messageHandlers.capture.postMessage({
        action: "dirty",
        dirty: textarea.value !== lastSavedValue
    });
}

textarea.addEventListener("input", updateDirtyState);

window.markSaved = function() {
    lastSavedValue = textarea.value;
    updateDirtyState();
};

window.resetPost = function() {
    textarea.value = "";
    lastSavedValue = "";
    updateDirtyState();
};

document.addEventListener("keydown", function(e) {
    if (e.metaKey && !e.ctrlKey && e.key.toLowerCase() === "s") {
        e.preventDefault();
        const text = textarea.value.trim();
        if (!text) return;
        window.webkit.messageHandlers.capture.postMessage({ action: "save", text: text });
        return;
    }

    if (e.metaKey && !e.ctrlKey && e.key.toLowerCase() === "w") {
        e.preventDefault();
        window.webkit.messageHandlers.capture.postMessage({ action: "closeRequest" });
        return;
    }
});
</script>
</body>
</html>
]]

-- State ---------------------------------------------------
function obj:resetCurrentPost()
    self.isDirty = false
    self.currentPost = nil
    if self.captureView then
        self.captureView:evaluateJavaScript([[
            if (window.resetPost) { window.resetPost(); }
        ]])
    end
end

function obj:focusEditor()
    if not self.captureView then return end

    self.captureView:show()
    self.captureView:bringToFront()

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
