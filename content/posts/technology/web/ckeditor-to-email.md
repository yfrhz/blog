---
title: "使用ckeditor发送邮件"
date: 2023-11-07T17:48:52+08:00
draft: false
---

## 背景

有个需求，要给客户批量发邮件。需要包含复杂表格，不能用excel，需要直接展示。\
最开始采用了WangEdit,简单快捷，但是表格功能不强，只能增减格子，于是又各种查，找到了ckeditor。
鉴于在实现过程中发现了很多坑，在此记录一下。\
多年老坑:\
[Possible to make editor.getData() returns content with inline styles?](https://github.com/ckeditor/ckeditor5/issues/1627)

## 环境

- 前端脚手架: umi
- node: V18

## 安装CkEditor

CKEditor有很多插件，不同的功能通过插件实现，安装的过程，就是将插件引入项目的过程。\
打开[Quick start](https://ckeditor.com/docs/ckeditor5/latest/installation/getting-started/quick-start.html)
可以安装步骤构建一个简单的富文本编辑器。\
但是显然这个简单的文本编辑器满足不了我的需求，但是有个[在线构建说明](https://ckeditor.com/docs/ckeditor5/latest/installation/getting-started/quick-start-other.html#creating-custom-builds-with-online-builder)
可以满足。\

1. 打开[在线构建页面](https://ckeditor.com/ckeditor-5/online-builder/)
    1. 选择Classic模式
    2. 然后按照需求选择插件，默认选择中的```Cloud Services```是高级功能，要加钱，不要可以去掉，下面右上角有```PREMIUM```
       标记的插件也是要加钱的。
    3. 然后选择哪些按钮常驻，哪些按钮隐藏（可以添加了插件，但是展示功能入口）
    4. 选择语言
    5. 然后就可以下载拉，如果选择的插件中有高级功能，会有一个要求添加```license key```的提示，可以返回第二步修改
2. 下载完成后是一个zip，解压后打开```sample/index.html```查看效果，如果合适，则开始引入项目。
    1. 安装必须组件
      ```shell
        // ckeditor react 组件
        yarn add  @ckeditor/ckeditor5-react @ckeditor/ckeditor5-build-classic
        // 将class转换为内联style,发邮件的时候用
        yarn add juice
      ```
    2. 将```build```目录下全部文件拷贝到```src/components/ckeditor```下,并添加```CkeditorUtil.ts``` 和 ```index.tsx```
```ts
// CkeditorUtil.ts
// 参考 https://github.com/ckeditor/ckeditor5/issues/1627

import juice from 'juice';

// @ts-ignore
export const CkeditorUtil = {
    getEditorStyles() {
        const cssTexts = [], rootCssTexts = [];
        for (const styleSheets of document.styleSheets) {
            // @ts-ignore
            if (styleSheets.ownerNode.hasAttribute('data-cke')) {
                for (const cssRule of styleSheets['cssRules']) {
                    if (cssRule.cssText.indexOf('.ck-content') !== -1) {
                        cssTexts.push(cssRule.cssText);
                    } else if (cssRule.cssText.indexOf(':root') !== -1) {
                        rootCssTexts.push(cssRule.cssText);
                    }
                }
            }
        }

        return cssTexts.length ? [...rootCssTexts, ...cssTexts].join(' ').trim() : '';
    },
    getContentWithLineStyles(editorContent: any) {
        // ck-content 参考 https://ckeditor.com/docs/ckeditor5/latest/installation/advanced/content-styles.html#sharing-content-styles-between-frontend-and-backend
        
        // Important!
        // If you take a closer look at the content styles, you may notice they are prefixed with the .ck-content class selector. 
        // This narrows their scope when used in CKEditor 5 so they do not affect the rest of the application. 
        // To use them in the front–end, you will have to add the ck-content CSS class to the container of your content. 
        // Otherwise the styles will not be applied.
        return juice.inlineContent(`<div class="ck-content">${editorContent}<div>`, this.getEditorStyles());
    }
};
```
```tsx
// index.tsx

import ClassicEditor from './ckeditor'

import {CKEditor} from '@ckeditor/ckeditor5-react';
import {EventInfo} from "@ckeditor/ckeditor5-utils";
import {type Editor} from 'ckeditor5/src/core'
export {CkeditorUtil} from "./CkeditorUtil"

interface Prop {
    disabled?: boolean
    initData?: string,
    onReady?: (editor: ClassicEditor) => void,
    onBlur?: (data: string, event: EventInfo<string, any>, editor: ClassicEditor) => void
    onFocus?: (data: string, event: EventInfo<string, any>, editor: ClassicEditor) => void
    onChange?: (data: string, event: EventInfo<string, any>, editor: ClassicEditor) => void
    autoSave?: (data: string, editor: Editor) => void
}

export {ClassicEditor};
export const ContentEditor = ({disabled = false, initData, autoSave, onReady, onBlur, onFocus, onChange}: Prop) => {

    return (
        <CKEditor
            disabled={disabled}
            editor={ClassicEditor}
            config={{
                autosave: {
                    save(editor) {
                        if (autoSave) {
                            autoSave(editor.data.get(), editor);
                        }
                        return Promise.resolve();
                    }
                },
            }}
            data={initData}
            onReady={editor => {
                if (onReady) {
                    onReady(editor);
                }
            }}
            onChange={(event, editor) => {
                if (onChange) {
                    onChange(editor.getData(), event, editor);
                }
            }}
            onBlur={(event, editor) => {
                if (onBlur) {
                    onBlur(editor.getData(), event, editor);
                }
            }}
            onFocus={(event, editor) => {
                if (onFocus) {
                    onFocus(editor.getData(), event, editor);
                }
            }}

        />
    )
}
```
## 使用
配置完成后便可开始使用
```tsx
import {ContentEditor, ClassicEditor, CkeditorUtil} from '@/components/ckeditor';
import {Button} from "antd";

export default function(){
   const [classicEditor, setClassicEditor] = useState<ClassicEditor>()

   const genInlineContent = () => {
       const originContent = classicEditor?.getData();
       if (!originContent) {
          return;
       }
       // 将原始html转换为内联样式
       // 不需要内联样式可以直接返回originContent
       return CkeditorUtil.getContentWithLineStyles(originContent);
   }
   
    const save = ()=>{
       console.log(genInlineContent())
    }
    
    return(
        <>
           <ContentEditor onReady={(editor) => setClassicEditor(editor)}/>
           <Button onClick={save}>保存</Button>
        </>
    )
}
```
