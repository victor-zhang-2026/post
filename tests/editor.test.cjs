// Run with: node --test tests/editor.test.cjs (no dependencies).
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(`${__dirname}/../Post.spoon/init.lua`, 'utf8');
const script = source.match(/<script>([\s\S]*?)<\/script>/)[1];

function editor(value, start = value.length, end = start) {
    const handlers = {};
    const messages = [];
    const textarea = {
        value, selectionStart: start, selectionEnd: end,
        addEventListener: (name, fn) => { handlers[name] = fn; },
        setSelectionRange(start, end) { this.selectionStart = start; this.selectionEnd = end; }
    };
    const document = {
        getElementById: () => textarea,
        addEventListener: (_, fn) => { handlers.documentKey = fn; },
        execCommand(command, _, text) {
            assert.equal(command, 'insertText');
            const { selectionStart: start, selectionEnd: end } = textarea;
            textarea.value = textarea.value.slice(0, start) + text + textarea.value.slice(end);
            textarea.setSelectionRange(start + text.length, start + text.length);
            handlers.input();
            return true;
        }
    };
    const window = { webkit: { messageHandlers: { capture: { postMessage: m => messages.push(m) } } } };
    vm.runInNewContext(script, { document, window });
    return {
        textarea, messages, window,
        key(key, modifiers = {}) {
            let prevented = false;
            const event = { key, ...modifiers, preventDefault: () => { prevented = true; } };
            handlers.keydown(event);
            handlers.documentKey(event);
            return prevented;
        }
    };
}

for (const [name, before, key, modifiers, after] of [
    ['dash continuation', '- 内容', 'Enter', {}, '- 内容\n- '],
    ['star continuation', '* 内容', 'Enter', {}, '* 内容\n* '],
    ['task continuation', '- [ ] 内容', 'Enter', {}, '- [ ] 内容\n- [ ] '],
    ['checked task resets', '- [x] done', 'Enter', {}, '- [x] done\n- [ ] '],
    ['star task', '* [X] done', 'Enter', {}, '* [X] done\n* [ ] '],
    ['nested task', '    - [ ] 内容', 'Enter', {}, '    - [ ] 内容\n    - [ ] '],
    ['tab-indented bullet', '\t* 内容', 'Enter', {}, '\t* 内容\n\t* '],
    ['empty dash exits', '- ', 'Enter', {}, ''],
    ['empty star exits', '* ', 'Enter', {}, ''],
    ['empty task exits', '- [ ] ', 'Enter', {}, ''],
    ['empty nested task exits', 'text\n    - [ ]   ', 'Enter', {}, 'text\n'],
    ['bare bullet exits', '-', 'Enter', {}, ''],
    ['bare task exits', '- [ ]', 'Enter', {}, ''],
    ['Tab indents bullet', '- 内容', 'Tab', {}, '    - 内容'],
    ['Tab indents task', '- [ ] 内容', 'Tab', {}, '    - [ ] 内容'],
    ['Tab indents plain line', '内容', 'Tab', {}, '    内容'],
    ['Shift Tab removes four spaces', '    - 内容', 'Tab', { shiftKey: true }, '- 内容'],
    ['Shift Tab removes partial indent', '  - 内容', 'Tab', { shiftKey: true }, '- 内容'],
    ['Shift Tab removes tab', '\t- 内容', 'Tab', { shiftKey: true }, '- 内容'],
    ['Shift Tab removes only one level', '        * 内容', 'Tab', { shiftKey: true }, '    * 内容'],
]) {
    test(name, () => {
        const e = editor(before);
        assert.equal(e.key(key, modifiers), true);
        assert.equal(e.textarea.value, after);
        assert.equal(e.textarea.selectionStart, after.length);
        assert.equal(e.messages.at(-1).action, 'dirty');
        assert.equal(e.messages.at(-1).dirty, after !== '');
    });
}

for (const [name, value, key, modifiers] of [
    ['heading uses normal Enter', '# 标题', 'Enter', {}],
    ['bold stays raw', '**重点**', 'Enter', {}],
    ['horizontal rule stays raw', '---', 'Enter', {}],
    ['hyphenated word stays raw', '-word', 'Enter', {}],
    ['Shift Enter stays native', '- 内容', 'Enter', { shiftKey: true }],
    ['IME Enter stays native', '- 内容', 'Enter', { isComposing: true }],
    ['legacy IME stays native', '- 内容', 'Enter', { keyCode: 229 }],
    ['IME Tab stays native', '- 内容', 'Tab', { isComposing: true }],
    ['Option D not intercepted', '- 内容', 'd', { altKey: true }],
    ['Command Tab not intercepted', '- 内容', 'Tab', { metaKey: true }],
    ['Control Tab not intercepted', '- 内容', 'Tab', { ctrlKey: true }],
    ['Option Enter not intercepted', '- 内容', 'Enter', { altKey: true }],
    ['Command Z not intercepted', '- 内容', 'z', { metaKey: true }],
]) {
    test(name, () => {
        const e = editor(value);
        assert.equal(e.key(key, modifiers), false);
        assert.equal(e.textarea.value, value);
        assert.equal(e.messages.length, 0);
    });
}

test('Enter splits content at caret and preserves following lines', () => {
    const e = editor('head\n- abcd\ntail', 9);
    e.key('Enter');
    assert.equal(e.textarea.value, 'head\n- ab\n- cd\ntail');
    assert.equal(e.textarea.selectionStart, 12);
});
test('selection replacement and marker editing stay native', () => {
    for (const [start, end] of [[2, 4], [0, 0], [1, 1]]) {
        const e = editor('- body', start, end);
        assert.equal(e.key('Enter'), false);
    }
});
test('Tab at beginning of empty first line indents that line', () => {
    const e = editor('\n- body', 0);
    e.key('Tab');
    assert.equal(e.textarea.value, '    \n- body');
    assert.equal(e.textarea.selectionStart, 4);
});
test('Tab preserves selected text on current line', () => {
    const e = editor('head\n- body\ntail', 7, 11);
    e.key('Tab');
    assert.equal(e.textarea.value, 'head\n    - body\ntail');
    assert.equal(e.textarea.selectionStart, 11);
    assert.equal(e.textarea.selectionEnd, 15);
    e.key('Tab', { shiftKey: true });
    assert.equal(e.textarea.value, 'head\n- body\ntail');
    assert.equal(e.textarea.selectionStart, 7);
    assert.equal(e.textarea.selectionEnd, 11);
});
test('Shift Tab at column zero is safe', () => {
    const e = editor('  - body', 0);
    e.key('Tab', { shiftKey: true });
    assert.equal(e.textarea.value, '- body');
    assert.equal(e.textarea.selectionStart, 0);
});
test('Shift Tab without indentation does not edit', () => {
    const e = editor('- body');
    assert.equal(e.key('Tab', { shiftKey: true }), true);
    assert.equal(e.textarea.value, '- body');
    assert.equal(e.messages.length, 0);
});
test('Command S sends raw Markdown; saved state and subsequent edits stay accurate', () => {
    const e = editor('# 标题\n- [ ] 任务\n**重点**');
    assert.equal(e.key('s', { metaKey: true }), true);
    assert.equal(e.messages.at(-1).action, 'save');
    assert.equal(e.messages.at(-1).text, e.textarea.value);
    e.window.markSaved();
    assert.equal(e.messages.at(-1).dirty, false);
    e.key('Tab');
    assert.equal(e.messages.at(-1).dirty, true);
    e.key('Tab', { shiftKey: true });
    assert.equal(e.messages.at(-1).dirty, false);
});
test('Command W still requests guarded close', () => {
    const e = editor('- unsaved');
    assert.equal(e.key('w', { metaKey: true }), true);
    assert.equal(e.messages.at(-1).action, 'closeRequest');
});
