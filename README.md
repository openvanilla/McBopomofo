# McBopomofo (Fork)

Fork of [openvanilla/McBopomofo](https://github.com/openvanilla/McBopomofo) — macOS 注音輸入法，新增簡拼輸入、免聲調輸入、SHIFT 中英切換等功能。

## New Features

### Abbreviated Bopomofo Input (簡拼輸入)

只打聲母就能輸入，例如打 `ㄋㄏ`（nh）即可匹配「你好」。

- `ReadingTrie` 資料結構，從詞庫建立 trie 索引，支援聲母前綴查詢
- `ParselessLM` 整合 trie，透過 `getAbbreviatedUnigrams()` 回傳候選詞（帶 -1.0 分數 penalty）
- `McBopomofoLM` 橋接層自動判斷是否為簡拼音節，透通路由至 trie 查詢
- `KeyHandler` 自動觸發：連續輸入兩個聲母時，前一個自動 commit 為簡拼 reading
- 也支援 Space 手動觸發

### Toneless Input (免聲調輸入)

不打聲調也能正確輸入，Viterbi walk 會根據上下文選出最佳聲調。

- 聲母+韻母輸入後，若下一個按鍵是新的聲母，自動 commit 當前音節（不需先打聲調）
- 無聲調音節查詢時，自動展開為全部 5 個聲調變體，回傳所有 unigram 讓 Viterbi 選擇最佳字
- 多音節詞組查詢同樣展開無聲調音節的所有組合，確保詞組匹配（例如 `ㄏㄡ-ㄗㄨㄛˋ` 能匹配「後座」）

### SHIFT Toggle (中英切換)

單獨按放 SHIFT（不搭配其他按鍵）即可切換注音/英數模式，螢幕顯示浮動通知。

- 透過 `flagsChanged` 偵測 SHIFT press-and-release
- 英數模式下直接 passthrough 按鍵給 macOS
- 切換輸入法時自動重設為注音模式
- 正確處理 SHIFT+modifier 組合鍵（不誤觸發）、CapsLock 共存
- 支援所有「空」狀態下切換（含 backspace 清空後的 `EmptyIgnoringPreviousState`）

## Build & Install

```bash
# Build
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofoInstaller \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build

# Install (launches installer GUI)
open ~/Library/Developer/Xcode/DerivedData/McBopomofo-*/Build/Products/Debug/McBopomofoInstaller.app
```

Or open `McBopomofo.xcodeproj` in Xcode, select **McBopomofoInstaller** scheme, Build & Run.

## Commit History

| Commit | Description |
|--------|-------------|
| `c03030f` | fix: address code review issues in SHIFT toggle |
| `02e9497` | feat: add SHIFT key toggle between Bopomofo and alphanumeric modes |
| `424e2c1` | chore: add test tools for abbreviated input testing |
| `83977cf` | feat: expand toneless syllables in multi-syllable LM queries |
| `6417bfb` | feat: expand toneless readings to all tone variants in LM |
| `ed06a23` | feat: auto-commit toneless syllables with best tone variant matching |
| `1e4ba68` | fix: add remote SPM packages to project level for CLI builds |
| `8b819c8` | fix: auto-commit syllable when new consonant would overwrite existing one |
| `4d985a2` | merge: abbreviated bopomofo input feature branch |
| `02441e8` | fix: address code review issues in abbreviated input |
| `5b666d2` | test: add end-to-end abbreviated input tests for KeyHandler |
| `959dff6` | test: add ReadingGrid integration test for abbreviated input |
| `6405f5f` | feat: emit consonant-only readings for abbreviated input in KeyHandler |
| `5682261` | feat: integrate abbreviated queries into McBopomofoLM |
| `dbfff88` | feat: add abbreviated query support to ParselessLM via ReadingTrie |
| `726544a` | feat: add ReadingTrie for abbreviated syllable matching |
| `2cf26b7` | feat: add isConsonantOnly() to BopomofoSyllable |

## License

MIT License (same as upstream). See [LICENSE.txt](LICENSE.txt).
