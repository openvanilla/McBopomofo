// Copyright (c) 2026 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#include <charconv>
#include <chrono>
#include <filesystem>
#include <iostream>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#if defined(__APPLE__)
#include <os/log.h>
#include <os/signpost.h>
#endif

#include "Mandarin/Mandarin.h"
#include "McBopomofoLM.h"
#include "gramambular2/reading_grid.h"

namespace {

using Formosa::Gramambular2::ReadingGrid;
using Formosa::Mandarin::BopomofoKeyboardLayout;
using Formosa::Mandarin::BopomofoReadingBuffer;
using McBopomofo::McBopomofoLM;

// Prevent the compiler from optimizing away the workload result.
template <typename T>
void DoNotOptimize(const T& value) {
  asm volatile("" : : "r"(&value) : "memory");
}

struct ProfilingScenario {
  const char* identifier;
  std::vector<std::string> keySequences;
  std::string expectedOutput;
};

struct ProfilingScenarioResult {
  const char* identifier;
  size_t iterations;
};

const std::vector<ProfilingScenario>& ProfilingScenarios() {
  static const std::vector<ProfilingScenario> scenarios = {
      {
          "short",
          {"su3", "cl3"},
          "你好",
      },
      {
          "medium",
          {"vul3", "a94", "5j4", "up", "gj", "bj4", "z83"},
          "小麥注音輸入法",
      },
      {
          "long",
          {"ji3", "yjo4", "1j4", "s/6", "j;4", "ru4", "2k7", "g4", "w8", "a93",
           "rm6", "y7", "g6", "2k7", "1o4", "u/3"},
          "我最不能忘記的是他買橘子時的背影",
      },
  };
  return scenarios;
}

#if defined(__APPLE__)
os_log_t ProfilingLog() {
  static os_log_t log =
      os_log_create("org.openvanilla.McBopomofo.EngineProfile",
                    OS_LOG_CATEGORY_POINTS_OF_INTEREST);
  return log;
}
#endif

class ScenarioInterval {
 public:
  explicit ScenarioInterval(const char* identifier) {
#if defined(__APPLE__)
    os_signpost_interval_begin(ProfilingLog(), OS_SIGNPOST_ID_EXCLUSIVE,
                               "Profiling Scenario", "identifier=%{public}s",
                               identifier);
#else
    static_cast<void>(identifier);
#endif
  }

  ~ScenarioInterval() {
#if defined(__APPLE__)
    os_signpost_interval_end(ProfilingLog(), OS_SIGNPOST_ID_EXCLUSIVE,
                             "Profiling Scenario");
#endif
  }

  ScenarioInterval(const ScenarioInterval&) = delete;
  ScenarioInterval& operator=(const ScenarioInterval&) = delete;
};

class EngineProfilingWorkload {
 public:
  explicit EngineProfilingWorkload(
      const std::filesystem::path& languageModelPath)
      : languageModel_(std::make_shared<McBopomofoLM>()),
        grid_(languageModel_),
        readingBuffer_(BopomofoKeyboardLayout::StandardLayout()) {
    languageModel_->loadLanguageModel(languageModelPath.c_str());
  }

  [[nodiscard]] bool isLoaded() const {
    return languageModel_->isDataModelLoaded();
  }

  std::string runScenario(const ProfilingScenario& scenario) {
    grid_.clear();
    readingBuffer_.clear();

    ReadingGrid::WalkResult walk;
    for (const std::string& keySequence : scenario.keySequences) {
      for (char key : keySequence) {
        readingBuffer_.combineKey(key);
      }
      grid_.insertReading(readingBuffer_.composedString());
      readingBuffer_.clear();
      walk = grid_.walk();
    }

    std::string text;
    for (const std::string& value : walk.valuesAsStrings()) {
      text += value;
    }
    return text;
  }

 private:
  std::shared_ptr<McBopomofoLM> languageModel_;
  ReadingGrid grid_;
  BopomofoReadingBuffer readingBuffer_;
};

std::optional<std::chrono::seconds> ParseProfileDuration(
    std::string_view value) {
  int duration = 0;
  const char* begin = value.data();
  const char* end = begin + value.size();
  const auto [position, error] = std::from_chars(begin, end, duration);
  if (error != std::errc{} || position != end) {
    return std::nullopt;
  }
  if (duration <= 0 || duration > 3600) {
    return std::nullopt;
  }
  return std::chrono::seconds{duration};
}

std::filesystem::path ResolveLanguageModelPath(
    const std::filesystem::path& executablePath) {
  const std::filesystem::path executableDirectory =
      std::filesystem::absolute(executablePath)
          .lexically_normal()
          .parent_path();
  return executableDirectory.parent_path() / "Data" / "data.txt";
}

bool VerifyWorkload(EngineProfilingWorkload& workload) {
  for (const ProfilingScenario& scenario : ProfilingScenarios()) {
    if (workload.runScenario(scenario) != scenario.expectedOutput) {
      return false;
    }
  }
  return true;
}

size_t RunScenarioForDuration(EngineProfilingWorkload& workload,
                              const ProfilingScenario& scenario,
                              std::chrono::steady_clock::duration duration) {
  const ScenarioInterval interval(scenario.identifier);
  const auto deadline = std::chrono::steady_clock::now() + duration;
  size_t iterations = 0;
  do {
    const std::string result = workload.runScenario(scenario);
    DoNotOptimize(result);
    ++iterations;
  } while (std::chrono::steady_clock::now() < deadline);
  return iterations;
}

std::vector<ProfilingScenarioResult> RunProfilingScenarios(
    EngineProfilingWorkload& workload, std::chrono::seconds duration) {
  const std::vector<ProfilingScenario>& scenarios = ProfilingScenarios();
  const std::chrono::steady_clock::duration totalDuration = duration;
  const auto scenarioDuration = totalDuration / scenarios.size();

  std::vector<ProfilingScenarioResult> results;
  results.reserve(scenarios.size());
  for (const ProfilingScenario& scenario : scenarios) {
    results.push_back({
        scenario.identifier,
        RunScenarioForDuration(workload, scenario, scenarioDuration),
    });
  }
  return results;
}

}  // namespace

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <PROFILE_DURATION>\n";
    return 1;
  }

  const auto profileDuration = ParseProfileDuration(argv[1]);
  if (!profileDuration.has_value()) {
    std::cerr << "Profile duration must be an integer between 1 and 3600.\n";
    return 1;
  }

  const std::filesystem::path languageModelPath =
      ResolveLanguageModelPath(argv[0]);
  EngineProfilingWorkload workload(languageModelPath);
  if (!workload.isLoaded()) {
    std::cerr << "Failed to load production language model data: "
              << languageModelPath << '\n';
    return 1;
  }

  if (!VerifyWorkload(workload)) {
    std::cerr << "Profiling workload verification failed.\n";
    return 1;
  }

  const std::vector<ProfilingScenarioResult> results =
      RunProfilingScenarios(workload, *profileDuration);
  for (const ProfilingScenarioResult& result : results) {
    std::cout << result.identifier << "_iterations=" << result.iterations
              << '\n';
  }
  return 0;
}
