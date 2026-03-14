# OpenVanilla McBopomofo 小麥注音輸入法

## 系統需求

小麥注音輸入法可以在 macOS 10.15 以上版本運作。如果您要自行編譯小麥注音輸入法，或參與開發，您需要：

- macOS 14.7 以上版本
- Xcode 15.3 以上版本
- Python 3.9 (可使用 Xcode 安裝後內附的，或是使用 homebrew 等方式安裝)

## 版本 3.1 新功能

### 近似音（模糊音）功能

本版本新增「近似音」功能，可幫助用戶在輸入時自動搜尋發音相近的候選詞，解決因發音混淆導致找不到正確候選字的問題。

#### 使用方式

在「偏好設定」→「進階」中勾選「使用近似音」即可啟用。

#### 支援的模糊配對

| 類型 | 配對 |
|------|------|
| 聲母 | ㄅ ↔ ㄆ |
| 聲母 | ㄍ ↔ ㄎ |
| 聲母 | ㄐ ↔ ㄑ |
| 聲母 | ㄓ ↔ ㄗ |
| 聲母 | ㄔ ↔ ㄘ |
| 聲母 | ㄕ ↔ ㄙ |
| 韻母 | ㄛ ↔ ㄜ |
| 韻母 | ㄣ ↔ ㄥ |
| 聲調 | 一聲 ↔ 二聲 ↔ 三聲 |

#### 使用範例

- 輸入「因該」可找到「應該」
- 輸入「除發」可找到「出發」
- 輸入「四十」可找到「事實」
- 輸入「營想」可找到「影響」

## 開發流程

用 Xcode 開啟 `McBopomofo.xcodeproj`，選 "McBopomofo Installer" target，build 完之後直接執行該安裝程式，就可以安裝小麥注音。

第一次安裝完，日後程式碼或詞庫有任何修改，只要重複上述流程，再次安裝小麥注音即可。

要注意的是 macOS 可能會限制同一次 login session 能 kill 同一個輸入法 process 的次數（安裝程式透過 kill input method process 來讓新版的輸入法生效）。如果安裝若干次後，發現程式修改的結果並沒有出現，或甚至輸入法已無法再選用，只要登出目前帳號再重新登入即可。

## 社群公約

歡迎小麥注音用戶回報問題與指教，也歡迎大家參與小麥注音開發。

首先，請參考我們在「[常見問題](https://github.com/openvanilla/McBopomofo/wiki/常見問題)」中所提「[我可以怎麼參與小麥注音？](https://github.com/openvanilla/McBopomofo/wiki/常見問題#我可以怎麼參與小麥注音)」一節的說明。

我們採用了 GitHub 的[通用社群公約](https://github.com/openvanilla/McBopomofo/blob/master/CODE_OF_CONDUCT.md)。公約的中文版請參考[這裡的翻譯](https://www.contributor-covenant.org/zh-tw/version/1/4/code-of-conduct/)。

## 軟體授權

本專案採用 MIT License 釋出，使用者可自由使用、散播本軟體，惟散播時必須完整保留版權聲明及軟體授權（[詳全文](https://github.com/openvanilla/McBopomofo/blob/master/LICENSE.txt)）。
