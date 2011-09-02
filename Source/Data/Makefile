data.txt: bin/cook.rb BPMFBase.txt BPMFMappings.txt PhraseFreq.txt \
          heterophony1.list heterophony2.list 1-4w.occ
	bin/cook.rb PhraseFreq.txt BPMFMappings.txt BPMFBase.txt $@
	cat BPMFPunctuations.txt >> $@

deploydata.txt: data.txt
	mv data.txt ${HOME}/Library/Input\ Methods/McBopomofo.app/Contents/Resources/data.txt
	killall -9 McBopomofo
	${HOME}/Library/Input\ Methods/McBopomofo.app/Contents/MacOS/McBopomofo install

PhraseFreq.txt: bin/buildFreq.bash 1-4w.occ
	bin/buildFreq.bash

#1-4w.occ: 1-4w.list bin/countphrase.bash
#	bin/countphrase.bash

1-4w.list: bin/build4wlist.bash BPMFBase.txt BPMFMappings.txt textpool.utf8
	bin/build4wlist.bash

clean:
	rm -f data.txt
