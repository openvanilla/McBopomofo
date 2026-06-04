// Copyright (c) 2024 and onwards The McBopomofo Authors.
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

#include <cassert>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <random>
#include <string>
#include <utility>

#include "MemoryMappedFile.h"
#include "gtest/gtest.h"

namespace McBopomofo {

class TempFile {
 public:
  TempFile(const char* initData, size_t length) {
    std::filesystem::path p = std::filesystem::temp_directory_path() /
                              "org.openvanilla.mcbopomofo.XXXXXX";
    path_ = p.native();

    int fd = mkstemp(path_.data());
    assert(fd != -1);

    ssize_t written = write(fd, initData, length);
    assert(static_cast<size_t>(written) == length);
    (void)written;

    close(fd);
  }

  ~TempFile() {
    std::error_code ec;
    bool result = std::filesystem::remove(path_, ec);
    assert(result);
    (void)result;
  }

  const char* path() const { return path_.c_str(); }

 protected:
  std::string path_;
};

class TempDir {
 public:
  TempDir() {
    std::filesystem::path p = std::filesystem::temp_directory_path() /
                              "org.openvanilla.mcbopomofo.XXXXXX";
    path_ = p.native();
    char* result = mkdtemp(path_.data());
    assert(result != nullptr);
    fprintf(stderr, "TEMPDIR: %s\n", result);
  }

  ~TempDir() {
    std::error_code ec;
    bool result = std::filesystem::remove(path_, ec);
    assert(result);
    (void)result;
  }

  const char* path() const { return path_.c_str(); }

 protected:
  std::string path_;
};

TEST(MemoryMappedFileTest, UnopenedInstance) {
  MemoryMappedFile mf;
  EXPECT_FALSE(mf.isOpen());
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);
}

TEST(MemoryMappedFileTest, BasicFunctionalities) {
  constexpr size_t kBufSize = 4 * 1024 * 1024;
  uint8_t* buf = new uint8_t[kBufSize];

  std::random_device rd;
  std::default_random_engine re(rd());

  std::uniform_int_distribution<unsigned int> randchar(0, 255);
  for (size_t i = 0; i < kBufSize; ++i) {
    buf[i] = static_cast<uint8_t>(randchar(re) & 0xff);
  }

  std::unique_ptr<TempFile> temp =
      std::make_unique<TempFile>(reinterpret_cast<char*>(buf), kBufSize);

  MemoryMappedFile mf;
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);
  EXPECT_FALSE(mf.isOpen());
  bool open_result = mf.open(temp->path());
  EXPECT_TRUE(open_result);
  EXPECT_TRUE(mf.isOpen());

  EXPECT_EQ(mf.length(), kBufSize);
  EXPECT_TRUE(mf.data() != nullptr);
  EXPECT_EQ(memcmp(mf.data(), buf, kBufSize), 0);

  mf.close();
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);
  EXPECT_FALSE(mf.isOpen());

  // Should be a no-op.
  mf.close();

  MemoryMappedFile mf2;
  open_result = mf2.open(temp->path());
  EXPECT_TRUE(open_result);
  EXPECT_EQ(mf2.length(), kBufSize);
  EXPECT_TRUE(mf2.data() != nullptr);
  EXPECT_TRUE(mf2.isOpen());

  MemoryMappedFile mf3(std::move(mf2));
  EXPECT_EQ(mf2.length(), 0);
  EXPECT_TRUE(mf2.data() == nullptr);
  EXPECT_EQ(mf3.length(), kBufSize);
  EXPECT_TRUE(mf3.data() != nullptr);
  EXPECT_FALSE(mf2.isOpen());
  EXPECT_TRUE(mf3.isOpen());

  MemoryMappedFile mf4 = std::move(mf3);
  EXPECT_EQ(mf3.length(), 0);
  EXPECT_TRUE(mf3.data() == nullptr);
  EXPECT_EQ(mf4.length(), kBufSize);
  EXPECT_TRUE(mf4.data() != nullptr);
  EXPECT_FALSE(mf3.isOpen());
  EXPECT_TRUE(mf4.isOpen());

  // Flip a byte of the underlying file. The map should reflect that.
  FILE* f = fopen(temp->path(), "r+b");
  EXPECT_NE(f, nullptr);
  EXPECT_NE(fputc(~buf[0], f), EOF);
  EXPECT_EQ(fclose(f), 0);

  EXPECT_NE(memcmp(mf4.data(), buf, kBufSize), 0);
  // The rest of the data should be the same.
  EXPECT_EQ(memcmp(mf4.data() + 1, buf + 1, kBufSize - 1), 0);

  mf4.close();
  EXPECT_TRUE(mf4.data() == nullptr);
  EXPECT_FALSE(mf4.isOpen());

  delete[] buf;

  std::string oldPath = temp->path();
  temp = nullptr;

  // Opening a non-existence file.
  MemoryMappedFile mf5;
  open_result = mf5.open(oldPath.c_str());
  EXPECT_FALSE(open_result);
  EXPECT_EQ(mf5.length(), 0);
  EXPECT_EQ(mf5.data(), nullptr);
  EXPECT_FALSE(mf5.isOpen());
}

TEST(MemoryMappedFileTest, OpenFailureOnEmptyFile) {
  std::filesystem::path tmp_file_path =
      std::filesystem::temp_directory_path() /
      "org.openvanilla.mcbopomofo.memorymappedfiletest-empty-file";
  std::filesystem::remove(tmp_file_path);
  std::ofstream out(tmp_file_path, std::ios::binary);
  out.close();

  MemoryMappedFile mf;
  EXPECT_FALSE(mf.open(tmp_file_path.c_str()));
  EXPECT_FALSE(mf.isOpen());
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);

  mf.close();
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);
  EXPECT_FALSE(mf.isOpen());

  std::filesystem::remove(tmp_file_path);
}

TEST(MemoryMappedFileTest, OpenFailureOnDirectory) {
  TempDir dir;
  MemoryMappedFile mf;
  EXPECT_FALSE(mf.open(dir.path()));
  EXPECT_FALSE(mf.isOpen());
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);

  mf.close();
  EXPECT_EQ(mf.length(), 0);
  EXPECT_EQ(mf.data(), nullptr);
  EXPECT_FALSE(mf.isOpen());
}

}  // namespace McBopomofo
