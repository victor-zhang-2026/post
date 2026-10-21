// Evaluate inside Post's WKWebView. Exercises the actual DOM and WebKit editing commands.
(() => {
    const results = [];
    function equal(actual, expected) { if (actual !== expected) throw Error(JSON.stringify({ actual, expected })); }
    function set(text = '') {
        editor.innerHTML = text ? markdownHTML(text) : '';
        editor.focus();
        selectContents(editor); getSelection().collapseToEnd();
    }
    function type(text) { document.execCommand('insertText', false, text); }
    function key(key, modifiers = {}) { editor.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...modifiers })); }
    function check(name, fn) {
        try { set(); fn(); results.push({ name, passed: true }); }
        catch (error) { results.push({ name, passed: false, error: String(error), html: editor.innerHTML }); }
    }
    for (const text of ['# 标题\n正文', '## 小标题\n**重点**和*斜体*', '- 内容\n- 下一项', '* 内容\n* 下一项', '- [ ] 任务\n- [x] 已完成', '- 父项\n    - 子项\n- 下项', '    - 缩进列表', '<img src=x onerror=alert(1)>']) {
        check('roundtrip: ' + text, () => { set(text); equal(getMarkdown(), text); });
    }
    check('typed dash becomes a visible bullet', () => { type('-'); type(' '); equal(editor.querySelectorAll('li').length, 1); type('内容'); equal(getMarkdown(), '- 内容'); });
    check('typed star becomes a visible bullet', () => { type('*'); type(' '); type('内容'); equal(getMarkdown(), '* 内容'); });
    check('typed heading becomes h1', () => { type('#'); type(' '); type('标题'); equal(editor.querySelector('h1')?.textContent, '标题'); equal(getMarkdown(), '# 标题'); });
    check('typed bold renders and saves Markdown', () => { type('**重点**'); equal(editor.querySelector('strong')?.textContent, '重点'); equal(getMarkdown(), '**重点**'); type('普通'); equal(getMarkdown(), '**重点**普通'); });
    check('typed italic renders', () => { type('*斜体*'); equal(editor.querySelector('em')?.textContent, '斜体'); equal(getMarkdown(), '*斜体*'); });
    check('Enter continues bullet', () => { type('- '); type('内容'); key('Enter'); equal(getMarkdown(), '- 内容\n- '); });
    check('empty bullet exits to plain line', () => { type('- '); key('Enter'); equal(editor.querySelectorAll('li').length, 0); equal(getMarkdown(), ''); });
    check('Enter after heading returns to body', () => { type('# '); type('标题'); key('Enter'); type('正文'); equal(getMarkdown(), '# 标题\n正文'); });
    check('task trigger renders checkbox', () => { type('- '); type('[ ] '); type('任务'); equal(editor.querySelectorAll('.task').length, 1); equal(getMarkdown(), '- [ ] 任务'); });
    check('task continuation resets checked state', () => { type('- '); type('[x] '); type('完成'); key('Enter'); type('下一项'); equal(getMarkdown(), '- [x] 完成\n- [ ] 下一项'); });
    check('empty task exits', () => { type('- '); type('[ ] '); key('Enter'); equal(editor.querySelectorAll('li').length, 0); equal(getMarkdown(), ''); });
    check('Tab and Shift Tab on list', () => { type('- '); type('父项'); key('Enter'); type('子项'); key('Tab'); equal(getMarkdown(), '- 父项\n    - 子项'); key('Tab', { shiftKey: true }); equal(getMarkdown(), '- 父项\n- 子项'); });
    check('Tab on a plain line', () => { type('正文'); key('Tab'); equal(getMarkdown(), '    正文'); key('Tab', { shiftKey: true }); equal(getMarkdown(), '正文'); });
    check('Shift Tab at outer list leaves bullet intact', () => { type('- '); type('内容'); key('Tab', { shiftKey: true }); equal(getMarkdown(), '- 内容'); });
    check('checkbox toggle serializes checked state', () => { set('- [ ] 任务'); editor.querySelector('.task').click(); equal(getMarkdown(), '- [x] 任务'); });
    check('HTML paste is escaped', () => { set('<script>alert(1)</script>'); equal(editor.querySelectorAll('script').length, 0); equal(getMarkdown(), '<script>alert(1)</script>'); });
    check('IME key handling does not process Enter', () => { type('- '); type('内容'); key('Enter', { isComposing: true }); equal(getMarkdown(), '- 内容'); });
    check('new task after exiting an existing list', () => { type('- '); type('内容'); key('Enter'); key('Enter'); type('- '); type('[ ] '); type('任务'); equal(editor.querySelectorAll('.task').length, 1); equal(getMarkdown(), '- 内容\n- [ ] 任务'); });
    check('new heading after exiting list', () => { type('- '); type('内容'); key('Enter'); key('Enter'); type('# '); type('标题'); equal(editor.querySelector('h1')?.textContent, '标题'); equal(getMarkdown(), '- 内容\n# 标题'); });
    check('first item indentation and return', () => { type('- '); type('内容'); key('Tab'); equal(getMarkdown(), '    - 内容'); key('Tab', { shiftKey: true }); equal(getMarkdown(), '- 内容'); });
    check('empty nested item exits fully', () => { type('- '); type('父项'); key('Enter'); key('Tab'); key('Enter'); type('正文'); equal(getMarkdown(), '- 父项\n正文'); });
    check('multiline paste retains heading, bullet, task and bold', () => { const data = new DataTransfer(); data.setData('text/plain', '# 标题\n- 项目\n- [ ] 任务\n**重点**'); editor.dispatchEvent(new ClipboardEvent('paste', { clipboardData: data, bubbles: true, cancelable: true })); equal(getMarkdown(), '# 标题\n- 项目\n- [ ] 任务\n**重点**'); equal(editor.querySelectorAll('.task').length, 1); });
    check('heading body returns to normal font', () => { type('# '); type('标题'); key('Enter'); type('正文'); const node = getSelection().anchorNode; equal(getComputedStyle(node.parentElement).fontSize, '18px'); equal(getComputedStyle(node.parentElement).fontWeight, '400'); });
    set(); window.markSaved();
    return JSON.stringify({ passed: results.filter(r => r.passed).length, total: results.length, results });
})()
