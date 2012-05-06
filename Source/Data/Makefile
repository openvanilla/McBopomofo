.PHONY: deploydata sort clean
DATPATH=Contents/Resources/data.txt
EXEPATH=Contents/MacOS/McBopomofo
EXENAME=McBopomofo

data.txt: bin/cook.rb BPMFBase.txt BPMFMappings.txt PhraseFreq.txt \
          heterophony1.list heterophony2.list phrase.occ
	bin/cook.rb PhraseFreq.txt BPMFMappings.txt BPMFBase.txt $@
	cat BPMFPunctuations.txt >> $@

deploydata: data.txt
	cp -p data.txt $${HOME}/Library/Input\ Methods/McBopomofo.app/$(DATPATH)
	while [ `ps xww|grep $(EXENAME)|grep -v grep|wc -l` -gt 0 ]; do \
	    killall -9 $(EXENAME); \
	    sleep 1; \
	done
	if [ "`sw_vers | awk -F '.' '/oductV/{print $$2}'`" == "5" ]; then \
	    $${HOME}/Library/Input\ Methods/McBopomofo.app/$(EXEPATH) install; \
	    echo extra install; \
	    sleep 2; \
	fi
	$${HOME}/Library/Input\ Methods/McBopomofo.app/$(EXEPATH) install

PhraseFreq.txt: bin/buildFreq.bash phrase.occ
	bin/buildFreq.bash

phrase.list: bin/build4wlist.bash BPMFBase.txt BPMFMappings.txt textpool.utf8
	bin/build4wlist.bash

sort: 
	@env LANG=C sort -k1 phrase.occ | uniq | grep -v '^$$' > tmp
	@mv tmp phrase.occ
	@env LANG=C sort -k1 BPMFMappings.txt | uniq | grep -v '^$$' > tmp
	@mv tmp BPMFMappings.txt
	@env LANG=C sort -k1 heterophony1.list|uniq>tmp
	@mv tmp heterophony1.list
	@env LANG=C sort -k1 heterophony2.list|uniq>tmp
	@mv tmp heterophony2.list
	@env LANG=C sort -k1 heterophony3.list|uniq>tmp
	@mv tmp heterophony3.list

check:
	@rm -f tmp1 tmp2
	@awk 'length($$1)/3!=NF-1' BPMFMappings.txt
	@awk '{print $$2,$$3,$$4,$$5,$$6,$$7}' BPMFMappings.txt | awk '/一/'
	awk '{print $$1}' BPMFMappings.txt | uniq|wc -l
	awk 'length($$1)>3{print $$1}' phrase.occ |wc -l

tidy:
	@sed -i '' -e 's/ //g' phrase.occ
	@sed -i '' -e 's/	/ /g;s/  / /g;s/ $$//g' BPMFMappings.txt
	@sed -i '' -e 's/｜/ㄧ/g;s/　/ /g' BPMFMappings.txt
	@sed -i '' -e 's/ [:0-9:]*$$//g' BPMFMappings.txt
	@sed -i '' -e 's/1/˙/g;s/2/ˊ/g;s/3/ˇ/g;s/4/ˋ/g' BPMFMappings.txt

clean:
	rm -f data.txt
