data.txt: bin/cook.rb BPMFBase.txt BPMFMappings.txt PhraseFreq.txt \
          heterophony1.list heterophony2.list phrase.occ
	bin/cook.rb PhraseFreq.txt BPMFMappings.txt BPMFBase.txt $@
	cat BPMFPunctuations.txt >> $@

deploydata.txt: data.txt
	mv data.txt ${HOME}/Library/Input\ Methods/McBopomofo.app/Contents/Resources/data.txt
	killall -9 McBopomofo; sleep 2
	${HOME}/Library/Input\ Methods/McBopomofo.app/Contents/MacOS/McBopomofo install

PhraseFreq.txt: bin/buildFreq.bash phrase.occ
	bin/buildFreq.bash

#phrase.occ: phrase.list bin/countphrase.bash
#	bin/countphrase.bash

phrase.list: bin/build4wlist.bash BPMFBase.txt BPMFMappings.txt textpool.utf8
	bin/build4wlist.bash

clean:
	rm -f data.txt
