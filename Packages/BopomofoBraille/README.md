# BopomofoBraille

Copyright (c) 2022 and onwards The McBopomofo Authors.

The package includes a converter that translates Taiwanese Bopomofo into
Taiwanese Braille, and vice versa.

The main class in the package is BopomofoBrailleConverter. You can use its
methods directly. For example:

```swift
let bpmf = "ㄓㄨㄥㄨㄣˊㄓㄨˋㄧㄣ"
let convertedBraille = BopomofoBrailleConverter.convert(bopomofo: bpmf)
let convertedBpmf = BopomofoBrailleConverter.convert(braille: convertedBraille)
```

The package helps implement the features in the Service menu, allowing users to
input Taiwanese Braille by pressing the Ctrl and Enter keys.
