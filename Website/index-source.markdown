# McBopomofo 小麥注音輸入法

最新版本：0.9.6.4 (Jan 18, 2013)

[下載連結](http://dl.openvanilla.org/file/mcbopomofo/McBopomofo-Installer-0.9.6.4.zip)

[新版功能介紹](http://osxchat.tumblr.com/post/36028711104/0-9-6)

## 特色

1.  輕巧簡單
2.  為 Mac User 量身打造
3.  支援標準、倚天、許氏、倚天26 鍵以及漢語拼音鍵盤配置
4.  程式反應快速，目前的詞庫也有相當的準確性，應該能夠有效幫助大家輸入國語。

## 安裝方式

安裝只需要把 zip 壓縮檔解壓縮然後執行安裝程式即可。如果原來已經有安裝小麥注音，安裝程式會直接覆蓋原有的輸入法。如果小麥注音變成灰色無法選擇，目前只好重新登出
再登入。

## 系統需求

Mac OS X 10.6 以上版本

## 軟體授權

本專案採用 MIT License 釋出，使用者可自由使用、散播本軟體，惟散播時必須保持軟體完整、不得修改版權文字。

小麥注音的輸入法引擎是 [Gramambular](https://github.com/lukhnos/formosana)，這是一套在 2010 年開發釋出的 open source 中文斷字引擎。斷字跟選字的原理相近，我們利用這個特性，加上網路上公開可使用的語料與讀音資料，整理成小麥注音的資料庫。

## 卸載方式

要反安裝小麥注音，請在 Finder 視窗中按著  鍵不放，繼續按 Shift 鍵和 G 鍵，這時會出現對話框，打入 ~/Library/Input Methods/ 按下 Enter 鍵，這時會跳出一個資料夾，將裡面的 McBopomofo 檔拖入垃圾桶，登出目前帳號再登入即可。

## 常見問題 (FAQ)

Q: 要怎麼輸入符號？

> 目前按下 '`' 按鈕之後，會有一個簡單的符號表。至於說相關的文件說明，我們因工作繁忙之故只能說抱歉了。

Q: 請問可以自己增加字庫嗎？

> 因為本輸入法還在很早的開發階段, 目前還沒開放這個功能。:-)

Q: 要如何提升資料品質？

> 請用 twitter 留言給 @[McBopomofo](https://twitter.com/McBopomofo)

Q: 為什麼只支援 Mac？

> 因為開發者都是 Mac user。另一方面，這個輸入法的引擎是跨平台的，我們樂見有人移植到其他平台上。:-)

Q: 哪裡可以取得原始碼？

> 請到 [github](https://github.com/OpenVanilla/McBopomofo/) 取得。

Q: 選字的原理是什麼？

> 簡化過的 Hidden Markov Model + Viterbi algorithm。請參考 [Formosana 原始碼](https://github.com/lukhnos/formosana)。

Q: 資料是從哪邊來的？
    
> 請參考[這張清單](textpool.html)
