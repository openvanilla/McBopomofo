# OpenVanilla McBopomofo 小麥注音輸入法

## 開發流程

用 Xcode 開啟 `McBopomofo.xcodeproj`，選 "McBopomofo Installer" target，build
完之後直接執行該安裝程式，就可以安裝小麥注音。

第一次安裝完，日後程式碼或詞庫有任何修改，只要重複上述流程，再次安裝小麥注音即可。

要注意的是 macOS 可能會限制同一次 login session 能 kill 同一個輸入法 process 的次數（
安裝程式透過 process killing來讓新版的輸入法生效）。如果安裝若干次後，發現程式修改的結果並
沒有出現，或甚至輸入法已無法再選用，只要登出目前帳號再重新登入即可。

## 軟體授權

本專案主要程式碼以及編譯後軟體採用 MIT License 釋出，使用者可自由使用、散播本軟體，惟散播本輸入法的原始碼時必須保持軟體完整原始碼、不得修改版權文字。

## Continuous Integration

我們使用 Travis-CI [![Build Status](https://travis-ci.org/openvanilla/McBopomofo.svg?branch=master)](https://travis-ci.org/openvanilla/McBopomofo) 作為雲端持續整合工具。
