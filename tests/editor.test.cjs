// No dependencies: node --test tests/editor.test.cjs
// Actual DOM/keyboard behavior is tested separately in editor-webkit.js.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(`${__dirname}/../Post.spoon/init.lua`, 'utf8');
const script = source.match(/<script>([\s\S]*?)<\/script>/)[1];
const context = vm.createContext({});
vm.runInContext(script.slice(script.indexOf('function escapeHTML'), script.indexOf('function inlineMarkdown')), context);
for (const [input, html] of [
    ['# 标题', '<h1>标题</h1>'],
    ['## 小标题', '<h2>小标题</h2>'],
    ['**重点**', '<div><strong>重点</strong></div>'],
    ['*斜体*', '<div><em>斜体</em></div>'],
    ['- 项目', '<ul><li data-marker="-">项目</li></ul>'],
    ['* 项目', '<ul><li data-marker="*">项目</li></ul>'],
    ['- ', '<ul><li data-marker="-"><br></li></ul>'],
    ['正文\n\n下一段', '<div>正文</div><div><br></div><div>下一段</div>'],
    ['<script>alert(1)</script>', '<div>&lt;script&gt;alert(1)&lt;/script&gt;</div>'],
]) test(input, () => assert.equal(context.markdownHTML(input), html));
test('task checkboxes retain Markdown state', () => {
    assert.match(context.markdownHTML('- [ ] 待办'), /data-task="false"/);
    assert.match(context.markdownHTML('- [x] 完成'), /data-task="true"/);
});
test('nested lists stay nested', () => {
    assert.equal(context.markdownHTML('- 父项\n    - 子项\n- 同级'), '<ul><li data-marker="-">父项<ul><li data-marker="-">子项</li></ul></li><li data-marker="-">同级</li></ul>');
});
test('pasted markup cannot create active HTML', () => {
    assert.doesNotMatch(context.markdownHTML('- <img src=x onerror=alert(1)>'), /<img/);
});
