OVTrainingSetFilter(){
    perl -p -e 's/font-family:\n/font-family: /' \
    | gsed -e '
    s/font-family: *新細明體/ /g
    s/font-family: *微軟..體/ /g
    s/font-family: *華康..體/ /g
    s/font-family:...華康..體/ /g
    s/LY\/繼續開會.html/ /g
    s/\(繼續閱讀\.\.\.\)/ /g
    s/記者...／..報導/ /g
    s/記者..／..報導/ /g
    s/／..報導/ /g
    s/【聯合晚報/ /g
    s/【聯合報/ /g
    s/〔自由時報/ /g
    s/中國時報【/ /g
    s/廣播電臺/廣播電台/g
    s/馬克思/馬克斯/g
    s/臺灣光復/台灣光復/g
    s/臺中企銀/台中企銀/g
    s/麻痹/麻痺/g
    s/証/證/g
    s/胱氨酸/胱胺酸/g
    s/甘氨酸/甘胺酸/g
    s/重頭笑到尾/從頭笑到尾/g
    s/重頭 來過/從頭 來過/g
    s/重頭開始/從頭開始/g
    s/重頭到尾/從頭到尾/g
    s/重頭寫/從頭寫/g
    s/重頭再來/從頭再來/g
    s/超級馬.歐/超級瑪利歐/g
    s/超級[馬,瑪][利,莉,琍,俐]/超級瑪利/g
    s/床第/床笫/g
    s/玆/茲/g
    /^$/d
    /^ *$/d
    /^頁$/d
' \
| python3 nonCJK_filter.py \
| sort -u
}
