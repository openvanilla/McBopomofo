#!/usr/bin/ruby
$KCODE="U"

if ARGV.size < 4
  $stderr.puts("usage: cook.rb phrase-freqs bpmf-mappings bpmf-base output")
  exit(1)
end

UNK_LOG_FREQ = -99.0
H_DEFLT_FREQ = -6.8

bpmf_chars = {}
bpmf_phrases = {}
phrases = {}
bpmf_phon1 = {}
bpmf_phon2 = {}
bpmf_phon3 = {}

# Reading-in a list of heterophonic words and
# its most frequent pronunciation
h1 = File.open("heterophony1.list")
while line = h1.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  key = elements[0]
  value = elements[1]
  bpmf_phon1[key] = [value]
end
h2 = File.open("heterophony2.list")
while line = h2.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  key = elements[0]
  value = elements[1]
  bpmf_phon2[key] = [value]
end
h3 = File.open("heterophony3.list")
while line = h3.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  key = elements[0]
  value = elements[1]
  bpmf_phon3[key] = [value]
end

o = File.open(ARGV[3], "w")

b = File.open(ARGV[2])
while line = b.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  
  type = elements[4]
  key = elements[0]
  value = elements[1]
  
  #if elements[4] == "big5"
    if bpmf_chars[key]
      bpmf_chars[key] += [value]
    else
      bpmf_chars[key] = [value]
    end
    
    if bpmf_phrases[key]
      bpmf_phrases[key] += [value]
    else
      bpmf_phrases[key] = [value]
    end
  #end
end

m = File.open(ARGV[1])
while line = m.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  key = elements.shift
  value = elements.join("-")
  if bpmf_phrases[key]
    bpmf_phrases[key] += [value]
  else
    bpmf_phrases[key] = [value]
  end
  #$stdout.puts("%s %d" % [key, key.length])
end

#phrases_blacklist ={}
#blacklist = File.open("blacklist.txt")
#while line = blacklist.gets
#  if line.match(/^#/)
#    next
#  end
#  line.chomp!
#  elements = line.split(/\s+/)
#  key = elements.shift
#  if key.length < 4
#    next
#  end
#  value = elements.join("-")
#  BL_LOG_FREQ = UNK_LOG_FREQ * Integer (key.length / 3 + 1) 
#  if phrases_blacklist[key]
#    phrases_blacklist[key] += [value]
#    o.puts("%s %s %d" % [key, value, BL_LOG_FREQ])
#  else
#    phrases_blacklist[key] = [value]
#    o.puts("%s %s %d" % [key, value, BL_LOG_FREQ])
#  end
#end

p = File.open(ARGV[0])
while line = p.gets
  if line.match(/^#/)
    next
  end
  line.chomp!
  elements = line.split(/\s+/)
  key = elements.shift
  #if phrases_blacklist[key]
  #  #$stdout.puts("%s %s" % [key, $stdout.puts("%s %s" % [key, phrases_blacklist[key]])])
  #  next
  #end
  value = elements.shift
  readings = bpmf_phrases[key]
  phrases[key] = true
  if readings
     # 一個字的長度目前還是 3 (unicode? or just CJK pages use length==3?)
     if key.length > 3
        readings.each do |r|
           o.puts("%s %s %s" % [key, r, value])
        end
     else
     # lookup the table from canonical list
        if bpmf_phon1[key]
           readings.each do |r|
              if bpmf_phon1[key].to_s == r
                 o.puts("%s %s %s" % [key, r, value])
              elsif bpmf_phon2[key].to_s == r
                 if value.to_f-0.28768207245178 > H_DEFLT_FREQ
                    o.puts("%s %s %f" % [key, r, value.to_f-0.28768207245178])
                 else
                    o.puts("%s %s %f" % [key, r, H_DEFLT_FREQ])
                 end
                 # l(3/4) = -0.28768207245178 / 頻率打七五折之意
              elsif bpmf_phon3[key].to_s == r
                 if value.to_f-0.28768207245178*2 > H_DEFLT_FREQ
                    o.puts("%s %s %f" % [key, r, value.to_f-0.28768207245178*2])
                 else
                    o.puts("%s %s %f" % [key, r, H_DEFLT_FREQ])
                 end
                 # l(3/4*3/4) = -0.28768207245178*2
              else
                 o.puts("%s %s %f" % [key, r, H_DEFLT_FREQ])
                 # 如果是破音字, set it to default.
                 # 很罕用的注音建議不要列入 heterophony?.list，這樣的話
                 # 就可以直接進來這個 condition
                 #$stdout.puts("%s\|%s\|" % [bpmf_phon1[key], r])
              end
           end
        else
           readings.each do |r|
              o.puts("%s %s %s" % [key, r, value])
           end
        end
     end
  end
end

bpmf_chars.each_pair do |k, v| 
  if !phrases[k]
    v.each do |r|
      o.puts("%s %s %f" % [k, r, UNK_LOG_FREQ])
    end
  end
end
