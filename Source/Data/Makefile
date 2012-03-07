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
	env LANG=C sort -k1 phrase.occ > tmp; mv tmp phrase.occ
	env LANG=C sort -sk1 BPMFMappings.txt > tmp; mv tmp BPMFMappings.txt

check:
	@awk 'length($$1)/3!=NF-1' BPMFMappings.txt
	@awk '{print $$2,$$3,$$4,$$5,$$6,$$7}' BPMFMappings.txt | awk '/一/'
	awk '{print $$1}' BPMFMappings.txt | uniq|wc -l
	awk 'length($$1)>3{print $$1}' phrase.occ |wc -l

tidy:
	sed -i '' -e 's/ //g' phrase.occ
	sed -i '' -e 's/  / /g;s/ $$//g' BPMFMappings.txt

clean:
	rm -f data.txt
