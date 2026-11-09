// mcb_tui.cpp - text-mode simulator of McBopomofo's keystroke -> candidate ->
// commit flow, driving the REAL engine (Mandarin reading buffer, McBopomofoLM,
// Gramambular2 ReadingGrid). The state machine is a port of the relevant parts
// of Source/KeyHandler.mm using default preferences.
//
// Usage:
//   mcb_tui <data.txt> [--user-dir DIR]                    interactive (raw terminal)
//   mcb_tui <data.txt> [--user-dir DIR] --script [--trace] read keys from stdin
//
// Script syntax: every character is a key press; newlines are ignored;
// special keys: <Enter> <Esc> <BS> <Del> <Left> <Right> <Up> <Down> <Home>
// <End> <PgUp> <PgDn> <Space>.   Example:  y94ji3qu/6z06<Down><Enter>
// (Do NOT put spaces between syllables: Space with an empty reading buffer
// opens the candidate window, exactly as in the real input method.)
//
// User phrases (port of the "marking" flow): Shift+Left/Right marks readings
// before/after the cursor (script: <SLeft>/<SRight>), Enter saves the marked
// phrase to <user-dir>/data.txt as "phrase reading-reading", Esc cancels.
// Files live in --user-dir DIR (default ./mcb_user): data.txt and
// exclude-phrases.txt, reloaded through McBopomofoLM::loadUserPhrases.
//
// User override model (port of KeyHandler.mm fixNode/suggest): picking a
// candidate is observed, and later input in the same context is re-overridden
// by suggest(). Overridden nodes are annotated on the Nodes line:
//   *[user score 42]            you picked it from the candidate window
//   *[model score -3.2]         soft suggestion (score of the top unigram)
//   *[model, forced score 42]   suggestion forcing a high score
// "own" is shown when it differs from the effective score. The model is
// in-memory only, with a 1.5 hour half-life; in --script mode <Wait=SECONDS>
// advances its clock so you can watch the suggestions decay.
//
// Punctuation: shifted punctuation keys (e.g. < > ? : ! " [ ]) insert the
// lexicon's _punctuation_Standard_<c> / _punctuation_<c> readings. The
// backtick ` opens the punctuation/symbol menu; inside it, typing a key such
// as ( < > A..Z shows that category (_punctuation_list_<c>).

#include <poll.h>
#include <termios.h>
#include <unistd.h>

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

#include "Mandarin/Mandarin.h"
#include "McBopomofoLM.h"
#include "UserOverrideModel.h"
#include "gramambular2/reading_grid.h"

using Formosa::Gramambular2::ReadingGrid;
using Formosa::Mandarin::BopomofoKeyboardLayout;
using Formosa::Mandarin::BopomofoReadingBuffer;

enum class K { Char, Enter, Esc, Backspace, Delete, Left, Right, Up, Down,
               Home, End, PageUp, PageDown, MarkLeft, MarkRight, Wait };
struct Key {
  K type;
  char ch = 0;
  double arg = 0;  // K::Wait: seconds to advance the model clock
};

static std::vector<std::string> utf8Chars(const std::string& s) {
  std::vector<std::string> out;
  for (size_t i = 0; i < s.size();) {
    unsigned char c = s[i];
    size_t n = c >= 0xF0 ? 4 : c >= 0xE0 ? 3 : c >= 0xC0 ? 2 : 1;
    out.push_back(s.substr(i, n));
    i += n;
  }
  return out;
}

static std::vector<std::string> readLines(const std::string& path) {
  std::vector<std::string> lines;
  std::ifstream f(path);
  for (std::string l; std::getline(f, l);) lines.push_back(l);
  return lines;
}

static void writeLines(const std::string& path,
                       const std::vector<std::string>& lines) {
  std::ofstream f(path, std::ios::trunc);
  for (const auto& l : lines) f << l << "\n";
}

static bool lineExists(const std::string& path, const std::string& line) {
  for (const auto& l : readLines(path)) {
    if (l == line) return true;
  }
  return false;
}

static void removeLine(const std::string& path, const std::string& line) {
  std::vector<std::string> kept;
  for (const auto& l : readLines(path)) {
    if (l != line) kept.push_back(l);
  }
  writeLines(path, kept);
}

static void appendLine(const std::string& path, const std::string& line) {
  auto lines = readLines(path);
  lines.push_back(line);
  writeLines(path, lines);
}

class Session {
 public:
  enum class Mode { Empty, Inputting, Choosing, Marking };
  static constexpr size_t kPageSize = 9;  // default candidate keys "123456789"

  Session(std::shared_ptr<McBopomofo::McBopomofoLM> lm,
          const std::string& userDir)
      : lm_(std::move(lm)),
        grid_(lm_),
        buf_(BopomofoKeyboardLayout::StandardLayout()),
        userPath_(userDir + "/data.txt"),
        excludePath_(userDir + "/exclude-phrases.txt") {
    std::filesystem::create_directories(userDir);
    for (const auto* p : {&userPath_, &excludePath_}) std::ofstream(*p, std::ios::app);
    reloadUserPhrases();
  }

  void handle(const Key& k) {
    status_.clear();
    if (k.type == K::Wait) {
      clockOffset_ += k.arg;
      status_ = "model clock advanced by " + std::to_string(static_cast<long>(k.arg)) + " s";
      return;
    }
    if (mode_ == Mode::Choosing) {
      handleChoosing(k);
    } else if (mode_ == Mode::Marking) {
      handleMarking(k);
    } else {
      handleComposing(k);
    }
  }

  std::string render() const {
    std::ostringstream o;
    o << "== McBopomofo text-mode simulator (real engine) ==\n";
    o << "Committed : " << committed_ << "\n";
    o << "Composing : " << composingLine() << "\n";
    o << "Mode      : "
      << (mode_ == Mode::Empty       ? "Empty"
          : mode_ == Mode::Inputting ? "Inputting"
          : mode_ == Mode::Marking   ? "Marking"
                                     : "ChoosingCandidate")
      << "\n";
    if (mode_ == Mode::Marking) {
      std::string tip;
      validateMark(&tip);
      o << "Tooltip   : " << tip << "\n";
    }
    o << "Nodes     : ";
    double total = 0;
    for (const auto& n : latest_.nodes) {
      o << n->value() << "(" << n->reading() << ")" << overrideLabel(n) << " ";
      total += n->score();
    }
    if (!latest_.nodes.empty()) o << " score=" << total;
    o << "\n";
    if (mode_ == Mode::Choosing) {
      size_t pages = (cands_.size() + kPageSize - 1) / kPageSize;
      o << "Candidates: " << (punctList_ ? "[punctuation menu] " : "") << "page "
        << (page_ + 1) << "/" << pages << ", " << cands_.size()
        << " total, for the reading before the cursor\n";
      size_t begin = page_ * kPageSize;
      size_t end = std::min(cands_.size(), begin + kPageSize);
      for (size_t i = begin; i < end; ++i) {
        o << (i == highlight_ ? "  > " : "    ") << (i - begin + 1) << ". "
          << cands_[i].display << "\n";
      }
    }
    if (!status_.empty()) o << "Status    : " << status_ << "\n";
    return o.str();
  }

 private:
  struct Cand {
    std::string reading, value, display;
  };

  std::shared_ptr<McBopomofo::McBopomofoLM> lm_;
  ReadingGrid grid_;
  BopomofoReadingBuffer buf_;
  std::string userPath_, excludePath_;
  size_t marker_ = 0;
  McBopomofo::UserOverrideModel uom_{500, 5400.0};  // as LanguageModelManager.mm
  double clockOffset_ = 0;
  enum class Src { User, Model, ModelForce };
  std::vector<std::pair<std::weak_ptr<ReadingGrid::Node>, Src>> tags_;
  ReadingGrid::WalkResult latest_;
  Mode mode_ = Mode::Empty;
  std::string committed_, status_;
  std::vector<Cand> cands_;
  size_t highlight_ = 0, page_ = 0;
  size_t originalCursor_ = 0, actualCursor_ = 0;
  bool punctList_ = false;  // candidate window is the ` punctuation menu

  void walk() { latest_ = grid_.walk(); }

  void refreshMode() {
    mode_ = (grid_.length() > 0 || !buf_.isEmpty()) ? Mode::Inputting
                                                    : Mode::Empty;
  }

  void beep(const std::string& why) { status_ = "(beep) " + why; }

  // Composing buffer with the pending bopomofo at the cursor (cf.
  // KeyHandler.mm buildInputtingState; a cursor inside a multi-reading node is
  // displayed at the end of that node).
  double now() const {
    using namespace std::chrono;
    return duration<double>(system_clock::now().time_since_epoch()).count() + clockOffset_;
  }

  // The engine does not expose who overrode a node, so remember it here.
  void tagNodeAt(size_t loc, Src src) {
    auto it = latest_.findNodeAt(loc);
    if (it == latest_.nodes.cend()) return;
    ReadingGrid::NodePtr node = *it;
    tags_.erase(std::remove_if(tags_.begin(), tags_.end(),
                               [&](const auto& t) {
                                 auto p = t.first.lock();
                                 return !p || p == node;
                               }),
                tags_.end());
    tags_.emplace_back(node, src);
  }

  std::string overrideLabel(const ReadingGrid::NodePtr& n) const {
    if (!n->isOverridden()) return "";
    std::string src = "override";
    bool force = false;
    for (const auto& t : tags_) {
      if (t.first.lock() != n) continue;
      src = t.second == Src::User ? "user" : "model";
      force = t.second == Src::ModelForce;
    }
    std::ostringstream o;
    o << "*[" << src << (force ? ", forced" : "") << " score " << n->score();
    double own = n->currentUnigram().score();
    if (own != n->score()) o << ", own " << own;
    o << "]";
    return o.str();
  }

  // Port of the suggest step in KeyHandler.mm after insertReading + walk.
  void suggestFromModel() {
    size_t cur = grid_.cursor();
    size_t actual = cur > 0 ? cur - 1 : cur;
    auto s = uom_.suggest(latest_, actual, now());
    if (s.empty()) return;
    auto type = s.forceHighScoreOverride
                    ? ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore
                    : ReadingGrid::Node::OverrideType::kOverrideValueWithScoreFromTopUnigram;
    if (!grid_.overrideCandidate(actual, s.candidate, type)) return;
    walk();
    tagNodeAt(actual, s.forceHighScoreOverride ? Src::ModelForce : Src::Model);
    status_ = "override model suggested " + s.candidate +
              (s.forceHighScoreOverride ? " (forced high score)" : " (soft, top-unigram score)");
  }

  std::string allText() const {
    std::string all;
    for (const auto& n : latest_.nodes) all += n->value();
    return all;
  }

  void reloadUserPhrases() {
    lm_->loadUserPhrases(userPath_.c_str(), excludePath_.c_str());
  }

  // Marked range [begin, end) in readings (== characters; see startMarking).
  std::pair<size_t, size_t> markRange() const {
    return {std::min(grid_.cursor(), marker_), std::max(grid_.cursor(), marker_)};
  }

  // Port of InputState.Marking.validate / userPhrase.
  bool validateMark(std::string* tip, std::string* line = nullptr) const {
    auto [b, e] = markRange();
    auto chars = utf8Chars(allText());
    std::string text, key;
    for (size_t i = b; i < e && i < chars.size(); ++i) text += chars[i];
    for (size_t i = b; i < e && i < grid_.readings().size(); ++i) {
      key += (i > b ? "-" : "") + grid_.readings()[i];
    }
    if (e == b) {
      tip->clear();
      return false;
    }
    if (e - b < 2) {
      *tip = "Marking \"" + text + "\": add a custom phrase by selecting two or more characters.";
      return false;
    }
    if (e - b > 8) {
      *tip = "The phrase being marked \"" + text + "\" is longer than the allowed 8 characters.";
      return false;
    }
    if (lineExists(userPath_, text + " " + key)) {
      *tip = "The phrase being marked \"" + text + "\" already exists.";
      return false;
    }
    *tip = "Marking \"" + text + "\". Press Enter to add it as a new phrase.";
    if (line) *line = text + " " + key;
    return true;
  }

  std::string markingLine() const {
    auto chars = utf8Chars(allText());
    auto [b, e] = markRange();
    size_t cur = grid_.cursor();
    std::string out;
    for (size_t i = 0; i <= chars.size(); ++i) {
      if (i == b) out += (cur == b ? "|{" : "{");
      if (i == e) out += (cur == e ? "}|" : "}");
      if (i < chars.size()) out += chars[i];
    }
    return out;
  }

  std::string composingLine() const {
    if (mode_ == Mode::Marking) return markingLine();
    std::string all;
    size_t running = 0, split = 0, cursor = grid_.cursor();
    for (const auto& n : latest_.nodes) all += n->value();
    for (const auto& n : latest_.nodes) {
      if (running >= cursor) break;
      split += n->value().size();
      running += n->spanningLength();
    }
    std::string pending = buf_.isEmpty() ? "" : "[" + buf_.composedString() + "]";
    return all.substr(0, split) + pending + "|" + all.substr(split);
  }

  void composeReading() {
    std::string r = buf_.syllable().composedString();
    buf_.clear();
    if (!lm_->hasUnigrams(r)) {
      beep("no entry for reading " + r);
      refreshMode();
      return;
    }
    grid_.insertReading(r);
    walk();
    suggestFromModel();
    refreshMode();
  }

  void commit() {
    for (const auto& n : latest_.nodes) committed_ += n->value();
    grid_.clear();
    buf_.clear();
    latest_ = ReadingGrid::WalkResult();
    mode_ = Mode::Empty;
  }

  void openCandidates() {
    originalCursor_ = grid_.cursor();
    // Default prefs (selectPhraseAfterCursorAsCandidate=false): candidates are
    // for the reading before the cursor; at the end that is the last one.
    actualCursor_ = originalCursor_ > 0 ? originalCursor_ - 1 : originalCursor_;
    auto raw = grid_.candidatesAt(actualCursor_);
    if (raw.empty()) {
      beep("no candidates");
      return;
    }
    std::unordered_map<std::string, size_t> count;
    for (const auto& c : raw) ++count[c.value];
    cands_.clear();
    for (const auto& c : raw) {
      std::string d = c.value;
      if (count[c.value] > 1) {
        std::string r = c.reading;
        std::replace(r.begin(), r.end(), '-', ' ');
        d += " (" + r + ")";
      }
      cands_.push_back({c.reading, c.value, d});
    }
    highlight_ = page_ = 0;
    mode_ = Mode::Choosing;
  }

  void select(size_t idx) {
    ReadingGrid::Candidate c(cands_[idx].reading, cands_[idx].value);
    // WalkResult references live nodes, so snapshot copies (see fixNode).
    ReadingGrid::WalkResult prev = latest_.copyWithFixedNodes();
    if (!grid_.overrideCandidate(actualCursor_, c)) {
      beep("override failed");
      return;
    }
    walk();
    tagNodeAt(actualCursor_, Src::User);
    auto nodeIt = latest_.findNodeAt(actualCursor_);
    if (nodeIt != latest_.nodes.cend() && (*nodeIt)->currentUnigram().score() > -8) {
      uom_.observe(prev, latest_, actualCursor_, now());
    }
    grid_.setCursor(originalCursor_);  // moveCursorAfterSelectingCandidate=false
    status_ = "selected " + cands_[idx].value;
    punctList_ = false;
    mode_ = Mode::Inputting;
  }

  // Deviation from the real app: it lets you enter marking and only refuses at
  // Enter when characters != readings; here we refuse to enter marking.
  void startMarking(bool left) {
    if (!buf_.isEmpty()) return beep("finish the bopomofo reading first");
    size_t cur = grid_.cursor();
    if (left ? cur == 0 : cur >= grid_.length()) return beep("nothing to mark");
    if (utf8Chars(allText()).size() != grid_.length()) {
      return beep("Certain Unicode symbols or characters not supported as user phrases.");
    }
    marker_ = left ? cur - 1 : cur + 1;
    mode_ = Mode::Marking;
  }

  void handleMarking(const Key& k) {
    switch (k.type) {
      case K::Esc:
        mode_ = Mode::Inputting;
        return;
      case K::Enter: {
        std::string tip, line;
        if (!validateMark(&tip, &line)) return beep(tip.empty() ? "invalid mark" : tip);
        removeLine(excludePath_, line);  // writing a phrase un-excludes it
        appendLine(userPath_, line);
        reloadUserPhrases();
        status_ = "saved user phrase: " + line;
        mode_ = Mode::Inputting;
        return;
      }
      case K::MarkLeft:
        if (marker_ == 0) return beep("marker at start");
        --marker_;
        break;
      case K::MarkRight:
        if (marker_ >= grid_.length()) return beep("marker at end");
        ++marker_;
        break;
      default:
        return beep("marking: Shift+Left/Right adjust, Enter saves, Esc cancels");
    }
    if (marker_ == grid_.cursor()) mode_ = Mode::Inputting;
  }

  // Port of the punctuation branch of KeyHandler.mm handleInput: the
  // layout-specific reading is tried first, then the generic one. (The
  // "press the same punctuation key again to cycle candidates" shortcut is not
  // implemented.)
  bool tryPunctuation(char c) {
    const std::string ch(1, c);
    for (const std::string& key :
         {"_punctuation_Standard_" + ch, "_punctuation_" + ch}) {
      if (!lm_->hasUnigrams(key)) continue;
      if (!buf_.isEmpty()) {
        beep("finish the bopomofo reading first");
        return true;
      }
      grid_.insertReading(key);
      walk();
      refreshMode();
      return true;
    }
    return false;
  }

  void openPunctuationMenu() {
    if (!lm_->hasUnigrams("_punctuation_list")) return beep("no punctuation menu");
    if (!buf_.isEmpty()) return beep("finish the bopomofo reading first");
    grid_.insertReading("_punctuation_list");
    walk();
    punctList_ = true;
    openCandidates();
    if (mode_ != Mode::Choosing) cancelPunctuationMenu();
  }

  void cancelPunctuationMenu() {
    punctList_ = false;
    grid_.deleteReadingBeforeCursor();
    walk();
    refreshMode();
  }

  void handleComposing(const Key& k) {
    switch (k.type) {
      case K::Char: {
        char c = k.ch;
        if (buf_.isValidKey(c)) {
          buf_.combineKey(c);
          if (buf_.hasToneMarker() && !buf_.hasToneMarkerOnly()) {
            composeReading();
          } else {
            refreshMode();
          }
          return;
        }
        if (c == ' ') {
          if (!buf_.isEmpty()) return composeReading();  // space = 1st tone
          if (grid_.length() > 0) return openCandidates();
          committed_ += " ";
          return;
        }
        if (c == '`') return openPunctuationMenu();
        if (tryPunctuation(c)) return;
        return beep(std::string("key ignored: ") + c);
      }
      case K::Enter:
        if (!buf_.isEmpty()) return composeReading();
        if (grid_.length() > 0) return commit();
        return;
      case K::Down:
        if (buf_.isEmpty() && grid_.length() > 0) return openCandidates();
        return beep("down");
      case K::MarkLeft:
      case K::MarkRight:
        return startMarking(k.type == K::MarkLeft);
      case K::Esc:  // not read from source: assumed behavior
        if (!buf_.isEmpty()) {
          buf_.clear();
          refreshMode();
        } else if (grid_.length() > 0) {
          grid_.clear();
          latest_ = ReadingGrid::WalkResult();
          refreshMode();
        }
        return;
      case K::Backspace:
        if (!buf_.isEmpty()) {
          buf_.backspace();
        } else if (!grid_.deleteReadingBeforeCursor()) {
          return beep("nothing to delete");
        } else {
          walk();
        }
        return refreshMode();
      case K::Delete:
        if (!buf_.isEmpty() || !grid_.deleteReadingAfterCursor()) {
          return beep("nothing to delete");
        }
        walk();
        return refreshMode();
      case K::Left:
        if (!buf_.isEmpty() || grid_.cursor() == 0) return beep("left");
        return grid_.setCursor(grid_.cursor() - 1);
      case K::Right:
        if (!buf_.isEmpty() || grid_.cursor() >= grid_.length()) return beep("right");
        return grid_.setCursor(grid_.cursor() + 1);
      case K::Home:
        if (buf_.isEmpty()) grid_.setCursor(0);
        return;
      case K::End:
        if (buf_.isEmpty()) grid_.setCursor(grid_.length());
        return;
      default:
        return beep("key ignored");
    }
  }

  // Navigation keys here are my approximation (KeyHandler.mm lines ~1700+ not
  // read); selection by number, cancel, and the post-selection grid update
  // follow the source.
  void handleChoosing(const Key& k) {
    size_t n = cands_.size();
    size_t pages = (n + kPageSize - 1) / kPageSize;
    switch (k.type) {
      case K::Char:
        if (k.ch >= '1' && k.ch <= '9') {
          size_t idx = page_ * kPageSize + (k.ch - '1');
          if (idx < n) return select(idx);
          return beep("no such candidate");
        }
        if (k.ch == ' ') {
          page_ = (page_ + 1) % pages;
          highlight_ = page_ * kPageSize;
          return;
        }
        if (punctList_) {  // menu category, e.g. ` then ( or < or A
          std::string key = std::string("_punctuation_list_") + k.ch;
          if (lm_->hasUnigrams(key)) {
            grid_.deleteReadingBeforeCursor();
            grid_.insertReading(key);
            walk();
            return openCandidates();
          }
        }
        return beep("key ignored");
      case K::Enter:
        return select(highlight_);
      case K::Down:
        if (highlight_ + 1 < n) ++highlight_;
        page_ = highlight_ / kPageSize;
        return;
      case K::Up:
        if (highlight_ > 0) --highlight_;
        page_ = highlight_ / kPageSize;
        return;
      case K::PageDown:
        page_ = (page_ + 1) % pages;
        highlight_ = page_ * kPageSize;
        return;
      case K::PageUp:
        page_ = (page_ + pages - 1) % pages;
        highlight_ = page_ * kPageSize;
        return;
      case K::Esc:
      case K::Backspace:
      case K::Delete:
        if (punctList_) return cancelPunctuationMenu();
        grid_.setCursor(originalCursor_);
        mode_ = Mode::Inputting;
        return;
      default:
        return beep("key ignored");
    }
  }
};

// ---------------------------------------------------------------- script mode
static std::vector<Key> parseScript(const std::string& s) {
  static const std::unordered_map<std::string, Key> names = {
      {"Enter", {K::Enter}}, {"Esc", {K::Esc}},       {"BS", {K::Backspace}},
      {"Del", {K::Delete}},  {"Left", {K::Left}},     {"Right", {K::Right}},
      {"Up", {K::Up}},       {"Down", {K::Down}},     {"Home", {K::Home}},
      {"End", {K::End}},     {"PgUp", {K::PageUp}},   {"PgDn", {K::PageDown}},
      {"Space", {K::Char, ' '}}, {"SLeft", {K::MarkLeft}}, {"SRight", {K::MarkRight}}};
  std::vector<Key> keys;
  for (size_t i = 0; i < s.size(); ++i) {
    char c = s[i];
    if (c == '\n' || c == '\r') continue;
    if (c == '<') {
      size_t j = s.find('>', i);
      if (j != std::string::npos) {
        std::string name = s.substr(i + 1, j - i - 1);
        if (name.rfind("Wait=", 0) == 0) {
          Key w{K::Wait};
          w.arg = std::atof(name.c_str() + 5);
          keys.push_back(w);
          i = j;
          continue;
        }
        auto it = names.find(name);
        if (it != names.end()) {
          keys.push_back(it->second);
          i = j;
          continue;
        }
      }
    }
    keys.push_back({K::Char, c});
  }
  return keys;
}

// ------------------------------------------------------------ interactive mode
static termios g_orig;
static void restoreTerminal() { tcsetattr(STDIN_FILENO, TCSAFLUSH, &g_orig); }

static bool readByte(int timeoutMs, unsigned char* out) {
  if (timeoutMs >= 0) {
    pollfd p{STDIN_FILENO, POLLIN, 0};
    if (poll(&p, 1, timeoutMs) <= 0) return false;
  }
  return read(STDIN_FILENO, out, 1) == 1;
}

// Returns false on quit (Ctrl-C / Ctrl-D / EOF).
static bool readKey(Key* key) {
  unsigned char c;
  while (true) {
    if (!readByte(-1, &c)) return false;
    if (c == 3 || c == 4) return false;
    if (c == 13 || c == 10) return *key = {K::Enter}, true;
    if (c == 127 || c == 8) return *key = {K::Backspace}, true;
    if (c == 27) {
      unsigned char d;
      if (!readByte(30, &d)) return *key = {K::Esc}, true;
      if (d != '[' && d != 'O') return *key = {K::Esc}, true;
      unsigned char e;
      std::string params;
      while (readByte(30, &e)) {
        if ((e >= '0' && e <= '9') || e == ';') {
          params += e;
          continue;
        }
        switch (e) {
          case 'A': return *key = {K::Up}, true;
          case 'B': return *key = {K::Down}, true;
          case 'C': return *key = {params == "1;2" ? K::MarkRight : K::Right}, true;
          case 'D': return *key = {params == "1;2" ? K::MarkLeft : K::Left}, true;
          case 'H': return *key = {K::Home}, true;
          case 'F': return *key = {K::End}, true;
          case '~':
            if (params == "3") return *key = {K::Delete}, true;
            if (params == "5") return *key = {K::PageUp}, true;
            if (params == "6") return *key = {K::PageDown}, true;
            if (params == "1" || params == "7") return *key = {K::Home}, true;
            if (params == "4" || params == "8") return *key = {K::End}, true;
            break;
        }
        break;
      }
      continue;  // unknown sequence: ignore
    }
    if (c >= 32 && c < 127) return *key = {K::Char, static_cast<char>(c)}, true;
  }
}

static void draw(const Session& s, bool interactive) {
  std::string screen = s.render();
  if (interactive) {
    std::string out = "\x1b[H\x1b[2J";
    for (char ch : screen) {
      if (ch == '\n') out += '\r';
      out += ch;
    }
    out += "\r\n(keys: Standard Daqian layout; Space/Down = candidates; "
           "Enter = commit; Ctrl-C = quit)\r\n";
    (void)!write(STDOUT_FILENO, out.data(), out.size());
  } else {
    std::cout << screen << std::flush;
  }
}

int main(int argc, char** argv) {
  if (argc < 2) {
    std::cerr << "usage: " << argv[0] << " <data.txt> [--script [--trace]]\n";
    return 2;
  }
  bool script = false, trace = false;
  std::string userDir = "./mcb_user";
  for (int i = 2; i < argc; ++i) {
    if (std::string(argv[i]) == "--script") script = true;
    if (std::string(argv[i]) == "--trace") trace = true;
    if (std::string(argv[i]) == "--user-dir" && i + 1 < argc) userDir = argv[++i];
  }
  auto lm = std::make_shared<McBopomofo::McBopomofoLM>();
  lm->loadLanguageModel(argv[1]);
  if (!lm->isDataModelLoaded()) {
    std::cerr << "failed to load language model: " << argv[1] << "\n";
    return 1;
  }
  Session session(lm, userDir);

  if (script) {
    std::string input((std::istreambuf_iterator<char>(std::cin)),
                      std::istreambuf_iterator<char>());
    for (const Key& k : parseScript(input)) {
      session.handle(k);
      if (trace) {
        std::cout << "--- key: "
                  << (k.type == K::Char ? std::string(1, k.ch) : "<special>")
                  << "\n";
        draw(session, false);
      }
    }
    if (!trace) draw(session, false);
    return 0;
  }

  if (!isatty(STDIN_FILENO)) {
    std::cerr << "stdin is not a terminal; use --script\n";
    return 2;
  }
  tcgetattr(STDIN_FILENO, &g_orig);
  atexit(restoreTerminal);
  termios raw = g_orig;
  raw.c_lflag &= ~(ICANON | ECHO | ISIG);
  raw.c_cc[VMIN] = 1;
  raw.c_cc[VTIME] = 0;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

  draw(session, true);
  Key k;
  while (readKey(&k)) {
    session.handle(k);
    draw(session, true);
  }
  (void)!write(STDOUT_FILENO, "\r\n", 2);
  return 0;
}
