# McBopomofo 統一使用者模型 — Stacked Branches 開發報告

## 概述

本報告記錄使用 Claude Code (Claude Opus 4.6) 開發 McBopomofo 輸入法「統一使用者模型」的完整過程，涵蓋三個 stacked branches 從設計、實作到程式碼審查的全部歷程。

**時間跨度**: 2026 年 2 月 8 日 02:52 JST — 2 月 9 日 01:09 JST（約 22 小時）

**最終分支狀態**:
```
master (4199b23)
 └── refactor/walk_strategy (f5c3d35)         ← Branch 1: +649 -93 行
      └── feat/contextual_user_model (cbb3870)     ← Branch 2: +1,229 -6 行
           └── feat/keyhandler_user_model (8d4236f)     ← Branch 3: +330 -192 行
```

**總變更量**: 13 個檔案，+2,200 -284 行（淨增 +1,916 行）

---

## 一、Session 全覽

共 15 個 Claude Code sessions（含設定與雜項），以下列出所有核心工作 sessions：

| # | Session ID | 時間 (JST) | 時長 | 大小 | 子代理 | 活動摘要 |
|---|-----------|-----------|------|------|--------|---------|
| 1 | 686c7ac9 | 02:52-03:00 | 8min | 48K | 0 | C++ 語言伺服器設定 |
| 2 | c0b648b0 | 03:00-03:02 | 2min | 8K | 0 | 插件安裝 |
| 3 | 2fc7e2da | 03:03-05:13 | 2h10m | 3.1M | 4 | PR #777 閱讀 + 架構設計 |
| 4 | 9c480a3c | 05:13-06:15 | 1h2m | 2.7M | 1 | Phase 0-3 核心實作 |
| 5 | cecf82cd | 06:15-06:37 | 22min | 1.1M | 3 | 實作延續（/clear 後）|
| 6 | 1436378d | 06:37-17:38 | 11h1m | 2.8M | 4 | Phase 4: KeyHandler 整合 |
| 7 | ef523bd8 | 17:38-17:50 | 12min | 724K | 1 | 建立 3 個 stacked branches |
| 8 | bfbe9f00 | 17:54-19:03 | 1h9m | 1.1M | 3 | 程式碼審查 Round 1 |
| 9 | 86c3fcce | 19:03-20:55 | 1h52m | 7.2M | 12 | 審查 Rounds 2-4 + 註解清理 |
| 10 | a784ab88 | 20:55-23:38 | 2h43m | 11M | 24 | 審查 Rounds 5-7 |
| 11 | e29a06e1 | 23:38-23:57 | 19min | 10M | 45 | Round 8A: Branch 1 |
| 12 | b1c07522 | 00:13-00:55 | 42min | 11M | 46 | Round 8B-C: Branch 2-3 |
| 13 | 8724b694 | 00:00-00:13 | 13min | 624K | 0 | Round 8 context reload |
| 14 | a8f7492c | 00:56-00:59 | 3min | 1.6M | 7 | Round 8 修復 |
| 15 | 439d5864+9001dc5e | 00:59-01:09 | 10min | 2.2M | 5 | Round 8 收尾 + 最終驗證 |

---

## 二、對話階段詳情

### 階段 A：環境設定與研究（02:52 — 05:13 JST）

#### 對話 1：C++ 語言伺服器設定
- **你的提問**：「for this repo, what do I need to install to support c++ language server?」
- **討論內容**：clangd 安裝、`compile_commands.json` 生成方式
- **互動次數**：13 user / 11 assistant

#### 對話 2：PR #777 深度閱讀 + 統一模型設計
- **你的提問**：「read https://github.com/openvanilla/McBopomofo/pull/777 carefully including resolved comments and explain to me in traditional chinese...」
- **討論內容**：
  - 深入分析 ChiahongHong 的 Viterbi 重構 PR
  - 五種分詞演算法比較（Viterbi / Beam Search / A* / Greedy / Forward-Backward）
  - 設計四層 KN backoff 使用者模型架構
  - 產出 1,275 行設計文件（`mighty-fluttering-pudding.md`）
- **互動次數**：134 user / 232 assistant（含 4 個子代理）

### 階段 B：核心實作（05:13 — 17:38 JST）

#### 對話 3：Phase 0-3 實作
- **你的提問**：「Implement the following plan: Unified User Model: Structural Fixes + Interpolated KN with Sub-Span Decomposition...」
- **實作內容**：
  - Phase 0A: 動態 span 長度（vector 取代 array<8>）
  - Phase 0B: Walk strategy 介面（ViterbiStrategy 等 4 種策略）
  - Phase 1: 結構性修正（fixedSpans_）
  - Phase 2: ContextualUserModel（四層 KN backoff）
  - Phase 3: Walk 整合（user model scoring + post-walk overrides）
- **互動次數**：204 user / 349 assistant（跨 2 sessions + /clear）

#### 對話 4：Phase 4 KeyHandler 整合
- **你的提問**：「Implement the following plan: Phase 4: KeyHandler Integration...」
- **實作內容**：
  - 簡化 `KeyHandler.mm` 的 insert/select 流程
  - `LanguageModelManager.mm` 全域 ContextualUserModel
  - 舊流程：insert → walk → UOM.suggest → override(score=42) → walk again
  - 新流程：insert → walk(userModel) ← 單次 pass
- **互動次數**：118 user / 188 assistant

### 階段 C：分支建立（17:38 — 17:50 JST）

#### 對話 5：Stacked Branch 建立
- **你的提問**：「Implement the following plan: Stacked Branches for Unified User Model (Phases 0-4)...」
- **操作**：從單一 commit 拆分為 3 個 stacked branches，每個有一個乾淨的 commit
- **互動次數**：41 user / 63 assistant

### 階段 D：程式碼審查 Rounds 1-7（17:54 — 23:38 JST）

#### 對話 6-8：多輪審查
- **你的提問**：
  - Round 1：「Code review for stacked branches...」
  - Rounds 2-4：「Code Review & Comment Cleanup for Stacked Branches...」
  - Rounds 5-7：「Code Review for Stacked Branches...」（新計劃、更深入）
- **審查成果**：
  - 清除了 ~66 個 AI 自動生成的不必要註解
  - 修復了 10 個 bugs
  - 簡化了 strategy pattern
- **互動次數**：544 user / 821 assistant（跨 3 sessions）
- **使用了 39 個審查子代理**

### 階段 E：Round 8 最終審查（23:38 JST — 01:09+1 JST）

#### 對話 9-11：Round 8 全面重新審查
- **你的提問**：「Implement the following plan: Round 8: Fresh Code Review — Stacked Branches...」
- **審查方法**：每個 branch 啟動 7 個並行審查代理（共 21 個/完整周期）：
  1. `pr-review-toolkit:code-reviewer` — 風格、bugs、最佳實踐
  2. `pr-review-toolkit:silent-failure-hunter` — 錯誤處理缺口
  3. `pr-review-toolkit:code-simplifier` — 簡化機會
  4. `pr-review-toolkit:comment-analyzer` — 註解品質
  5. `pr-review-toolkit:type-design-analyzer` — 型別設計品質
  6. `coderabbit:code-reviewer` — CodeRabbit AI 審查
  7. `feature-dev:code-reviewer` — bugs、邏輯錯誤、安全性
- **修復了 4 個問題**（詳見下方）
- **互動次數**：~503 user / ~827 assistant（跨 5+ sessions）
- **使用了 ~103 個審查子代理**

---

## 三、分支實作詳情

### Branch 1: `refactor/walk_strategy`（7 檔案 +649 -93 行）

| 檔案 | 變更 |
|------|------|
| `language_model.h` | 新增 `maxKeyLength()` 虛擬方法 |
| `reading_grid.h` | 動態 span（vector 取代 array<8>）、fixedSpans、walk delegation |
| `reading_grid.cpp` | 重構 walk() 委派至策略、fixSpan/clearFixedSpans 實作 |
| `walk_strategy.h` | **新檔案**: Strategy Pattern 介面 |
| `walk_strategy.cpp` | **新檔案**: RunViterbi + 4 種策略 |
| `reading_grid_test.cpp` | +8 測試（6 FixedSpan + 3 AlgoComparison = 29 總計）|
| `CMakeLists.txt` | 更新來源檔案 |

**Commit**: `f5c3d35 refactor: extract walk strategy and add dynamic span support`
**Commit 時間**: 2026-02-08 17:56:50 +0900

### Branch 2: `feat/contextual_user_model`（8 檔案 +1,229 -6 行）

| 檔案 | 變更 |
|------|------|
| `contextual_user_model.h` | **新檔案**: 四層 KN backoff 模型介面 |
| `contextual_user_model.cpp` | **新檔案**: 309 行核心演算法實作 |
| `reading_grid.h` | userModel 整合、post-walk overrides |
| `reading_grid.cpp` | selectOverrideUnigram、post-walk 使用者模型建議 |
| `walk_strategy.h` | Relax() 新增 user model 參數 |
| `walk_strategy.cpp` | user model scoring 整合 |
| `reading_grid_test.cpp` | +24 測試（9 ContextualUserModel + 15 IntegratedWalk = 53 總計）|
| `CMakeLists.txt` | 更新來源檔案 |

**核心演算法**: Interpolated Kneser-Ney 四層 backoff
1. **Bigram**: P(w | left_context) — 使用者觀察紀錄，含時間衰減
2. **Continuation**: P_cont(w) — 不同左上下文的數量
3. **Base LM**: P_base(w) — data.txt ~160K 詞條
4. **Decomposed**: ΠP_base(syllable_i) — 未知詞的音節分解

**參數**: 折扣 d=0.5, 衰減半衰期=20, 最低機率=1e-10

**Commit**: `cbb3870 feat: add contextual user model with KN backoff scoring`
**Commit 時間**: 2026-02-08 18:09:49 +0900

### Branch 3: `feat/keyhandler_user_model`（5 檔案 +330 -192 行）

| 檔案 | 變更 |
|------|------|
| `KeyHandler.mm` | 簡化 insert/select 流程，接入 contextualUserModel |
| `LanguageModelManager.mm` | 全域 ContextualUserModel 實例、load/save |
| `LanguageModelManager+Privates.h` | 新增 contextualUserModel 屬性 |
| `McBopomofo.xcodeproj` | 加入新檔案參照 |
| `reading_grid_test.cpp` | +1 測試 = 54 總計 |

**流程簡化**:
- 舊: insert → walk → UOM.suggest → overrideCandidate(score=42) → walk again
- 新: insert → walk(userModel) ← 單次 pass，KN-smoothed scores 內建

**Commit**: `8d4236f feat: integrate contextual user model into KeyHandler`
**Commit 時間**: 2026-02-08 21:47:04 +0900

---

## 四、程式碼審查修復紀錄

### Round 8 修復（4 個問題，3 HIGH + 1 LOW-MED）

| Branch | 嚴重度 | 修復內容 | 檔案 |
|--------|--------|---------|------|
| 1 | HIGH | "shortest-path" → "longest-path" 註解錯誤 | walk_strategy.h |
| 1 | HIGH | MMSEG/SegmentViterbi 加入 placeholder 註解（尚未實作的策略） | walk_strategy.h |
| 2 | HIGH | `selectOverrideUnigram` 回傳值未檢查，可能跳過有效建議 | reading_grid.cpp:194-197 |
| 3 | LOW-MED | `"_START_"` 魔術字串替換為 `kStartSentinel` 常數 | KeyHandler.mm:210 |

### 排除的誤報

| 問題 | 排除原因 |
|------|---------|
| Lambda `[&readingStr]` 捕獲 | 同步執行，捕獲的參照在 lambda 生命周期內有效 |
| Iterator bounds check | `!= cbegin()` 已足夠保證 `*(iter - 1)` 安全 |
| Missing node validation | 程式碼已有檢查，審查代理隨後撤回了此項 |

### Rounds 1-7 累計修復

- 清除 ~66 個 AI 自動生成的冗餘註解
- 修復 10 個 bugs
- 簡化 strategy pattern 設計

---

## 五、Token 使用與成本

### 各階段 Token 使用

| 階段 | Sessions | 輸出 Tokens | 快取讀取 | 快取建立 | 子代理 |
|------|----------|------------|---------|---------|--------|
| 環境設定 + 研究設計 | 3 | 33,652 | 24,495,125 | 905,319 | 4 |
| 核心實作 (Phase 0-4) | 3 | 43,722 | 54,716,122 | 2,814,654 | 8 |
| 分支建立 | 1 | 6,427 | 5,248,916 | 254,601 | 1 |
| 審查 Rounds 1-7 | 3 | 45,577 | 76,627,261 | 3,120,698 | 39 |
| Round 8 最終審查 | 5 | 30,603 | 47,271,647 | 3,557,377 | 103 |
| **合計** | **15** | **159,981** | **208,359,071** | **10,652,649** | **155** |

### Token 統計摘要

| 指標 | 數值 |
|------|------|
| 輸出 tokens 合計 | 159,981 |
| 快取讀取 tokens 合計 | 208,359,071（~208M）|
| 快取建立 tokens 合計 | 10,652,649（~10.7M）|
| 有效輸入 tokens 合計 | ~219,132,000（~219M）|
| API 呼叫總數 | ~2,330 |

### /insights 全域統計（stats-cache.json）

以下為 `/insights` 的全域統計資料（涵蓋所有專案，非僅 McBopomofo）：

**McBopomofo 工作日**:

| 日期 (UTC) | 對應 JST | 訊息數 | Sessions | 工具呼叫 | 輸出 Tokens |
|-----------|---------|--------|----------|---------|------------|
| 2026-02-07 | 2/8 白天 | 28,228 | 60 | 4,388 | 944,933 |
| 2026-02-08 | 2/8 晚-2/9 凌晨 | 26,168 | 62 | 4,202 | 629,486 |

**claude-opus-4-6 全期使用統計**:

| 指標 | 數值 |
|------|------|
| 輸入 tokens | 782,446 |
| 輸出 tokens | 2,146,964 |
| 快取讀取 | 2,481,332,835（~2.48B）|
| 快取建立 | 131,222,845（~131M）|
| 總 sessions（所有專案） | 525 |
| 總訊息（所有專案） | 245,066 |
| 首次使用日期 | 2025-12-26 |

**最活躍時段**（以 UTC 計，所有專案）:
- 最高峰: 17:00-18:00 UTC（02:00-03:00 JST）— 48 sessions
- 次高峰: 17:00 UTC（43 sessions）、15:00 UTC（42 sessions）

---

## 六、時間分配

| 階段 | 時長 | 佔比 |
|------|------|------|
| 環境設定 + 研究設計 | ~2.5 小時 | 11% |
| 核心實作（Phase 0-4） | ~12.5 小時 | 56% |
| 分支建立 | ~12 分鐘 | 1% |
| 程式碼審查 R1-7 | ~5.7 小時 | 25% |
| 最終審查 R8 | ~1.5 小時 | 7% |
| **總計** | **~22.2 小時** | 100% |

> **註**: 時間跨度（22 小時）包含可能的休息/中斷時間（特別是 Phase 4 的 06:37-17:38 區間），實際活躍 coding 時間可能較短。

---

## 七、程式碼產出統計

| 指標 | 數值 |
|------|------|
| 修改檔案數 | 13 |
| 新增行數 | +2,200 |
| 刪除行數 | -284 |
| 淨增行數 | +1,916 |
| 新建檔案 | 4（walk_strategy.h/.cpp, contextual_user_model.h/.cpp）|
| C++ 測試新增 | 33 個（從 21 → 54）|
| XCTests | 35 個（未變動）|
| Session 資料總大小 | ~56 MB |

### 測試結果

| Branch | 測試數 | 結果 |
|--------|--------|------|
| refactor/walk_strategy | 29/29 | 全部通過 |
| feat/contextual_user_model | 53/53 | 全部通過 |
| feat/keyhandler_user_model | 54/54 | 全部通過 |

壓力測試（8,001 readings）：~14-15ms，效能無衰退。

---

## 八、已知延遲問題

以下問題在審查中被記錄但延遲到後續 Phase 5/6 處理：

| # | 問題 | 預計處理 |
|---|------|---------|
| 1 | 每次選字都存檔（主執行緒同步 I/O） | Phase 5 |
| 2 | `gContextualUserModel` 線程安全 | Phase 5 |
| 3 | bigram store 無容量上限/驅逐機制 | Phase 5 |
| 4 | 舊版 `_userOverrideModel` 死碼 | Phase 5 |
| 5 | Aliasing `shared_ptr` 脆弱性 | Phase 5 |
| 6 | `loadFromFile` 空白字元解析脆弱性 | Phase 5 |
| 7 | `fixedSpans_` 在 reading insert/delete 時未失效 | Phase 5 |

---

## 九、設計文件與計劃檔案

> **Note**: The `~/.claude/` paths below are from the author's
> local development environment. These files are not part of
> the repository and are not expected to be available to other
> contributors. They are listed here for provenance and
> reproducibility of the analysis.

| 文件 | 路徑 | 用途 |
|------|------|------|
| 統一使用者模型設計 | `~/.claude/plans/mighty-fluttering-pudding.md` | Phase 0-6 完整設計（1,275 行）|
| Round 8 審查計劃 | `~/.claude/plans/memoized-toasting-bumblebee.md` | 最終審查計劃與結果 |
| 架構文件 | `~/.claude/projects/.../memory/architecture.md` | 技術架構摘要 |
| 專案記憶 | `~/.claude/projects/.../memory/MEMORY.md` | 持久化的專案知識 |

---

## 十、資料來源說明

> **Note**: Data source paths referencing `~/.claude/` are
> author-local and not included in this repository.

- **Token 使用數據**: 從 15 個 session JSONL 日誌中直接提取（`~/.claude/projects/.../*.jsonl`）
- **/insights 數據**: 從 `~/.claude/stats-cache.json` 提取（全域統計，涵蓋所有專案）
- **Git 歷史**: 從 `git log` 和 `git reflog` 提取
- **審查結果**: 從計劃檔案 `memoized-toasting-bumblebee.md` 提取
- **Session 中的互動次數**: 包含系統訊息（/clear、hook 觸發等），實際使用者輸入訊息數較少
- **快取讀取 tokens（~208M）**: 反映了大量上下文重用，大幅降低了實際 API 成本
