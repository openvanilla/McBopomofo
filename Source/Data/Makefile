PYTHON ?= python3

.PHONY: sort clean

all: data.txt data-plain-bpmf.txt associated-phrases-v2.txt

install: all

data-plain-bpmf.txt: curation/compilers/plain_bpmf_compiler.py BPMFBase.txt BPMFPunctuations.txt
	$(PYTHON) -m curation.compilers.plain_bpmf_compiler BPMFBase.txt BPMFPunctuations.txt data-plain-bpmf.txt

data.txt: curation/compilers/main_compiler.py BPMFBase.txt BPMFMappings.txt BPMFPunctuations.txt \
          PhraseFreq.txt phrase.occ Symbols.txt Macros.txt\
          heterophony1.list heterophony2.list heterophony3.list
	$(PYTHON) -m curation.compilers.main_compiler \
		--heterophony1 heterophony1.list \
		--heterophony2 heterophony2.list \
		--heterophony3 heterophony3.list \
		--phrase_freq PhraseFreq.txt \
		--bpmf_mappings BPMFMappings.txt \
		--bpmf_base BPMFBase.txt \
		--punctuations BPMFPunctuations.txt \
		--symbols Symbols.txt \
		--macros Macros.txt \
		--output data.txt

associated-phrases-v2.txt: data.txt curation/builders/phrase_deriver.py associated-punctuation.txt
		$(PYTHON) -m curation.builders.phrase_deriver $< $@ associated-punctuation.txt

PhraseFreq.txt: curation/builders/frequency_builder.py phrase.occ exclusion.txt
	$(PYTHON) -m curation.builders.frequency_builder

clean:
	rm -f data.txt data-plain-bpmf.txt phrase.list

# FOR INTERNAL USE
_install: tidy sort check all
	@cp -a data.txt data-plain-bpmf.txt $(HOME)/Library/Input\ Methods/McBopomofo.app/Contents/Resources/
	@pkill -HUP -f McBopomofo || echo McBopomofo is not running
_deploy: _install
	@rsync -avx data.txt data-plain-bpmf.txt $(RHOST):"Library/Input\ Methods/McBopomofo.app/Contents/Resources/"
	@test "$(RHOST)" && ssh $(RHOST) "pkill -HUP -f McBopomofo || echo McBopomofo is not running" || true

sort:
	@sort -k1 phrase.occ | uniq | grep -v '^$$' > tmp
	@mv tmp phrase.occ
	@sort -k1 BPMFMappings.txt | uniq | grep -v '^$$' > tmp
	@mv tmp BPMFMappings.txt
	@env LANG=C sort -k1 heterophony1.list|uniq>tmp
	@mv tmp heterophony1.list
	@env LANG=C sort -k1 heterophony2.list|uniq>tmp
	@mv tmp heterophony2.list
	@env LANG=C sort -k1 heterophony3.list|uniq>tmp
	@mv tmp heterophony3.list
	@env LANG=C sort -k1 exclusion.txt|uniq>tmp
	@mv tmp exclusion.txt

check: SHELL:=/bin/bash
check:
	@awk 'length($$1)/3!=NF-1' BPMFMappings.txt
	@awk '{print $$2,$$3,$$4,$$5,$$6,$$7}' BPMFMappings.txt | awk '/一/'
	@diff -u <(awk '{print $$1}' BPMFMappings.txt|sort -u) \
                 <(awk 'length($$1)>3{print $$1}' phrase.occ|sort -u)

tidy:
	@sed -i '' -e 's/ //g' phrase.occ
	@sed -i '' -e 's/	/ /g;s/  / /g;s/ $$//g' BPMFMappings.txt
	@sed -i '' -e 's/｜/ㄧ/g;s/　/ /g' BPMFMappings.txt
	@sed -i '' -e 's/ [:0-9:]*$$//g' BPMFMappings.txt
	@sed -i '' -e 's/1/˙/g;s/2/ˊ/g;s/3/ˇ/g;s/4/ˋ/g' BPMFMappings.txt

_phrase.occ: phrase.list
	@$(PYTHON) scripts/count_occurrences.py phrase.list > tmp && mv tmp phrase.occ

phrase.list: BPMFBase.txt BPMFMappings.txt
	awk 'length($$1)<4{print $$1}' BPMFBase.txt > tmp
	awk '{print $$1}'         BPMFMappings.txt >> tmp
	sort -u tmp | uniq > phrase.list
_myclean:
	cd ../.. && xcodebuild -derivedDataPath build clean
_myprodbuild:
	cd ../.. && \
        xcodebuild \
          -scheme McBopomofo \
          -configuration Release \
          -derivedDataPath build \
          build
_mydebugbuild:
	cd ../.. && \
        xcodebuild \
          -scheme McBopomofo \
          -configuration Debug \
          -derivedDataPath build \
          build
_mycodecheck:
	@for myfile in curation/*/*.py scripts/*.py; do \
            pycodestyle --ignore=E501,E722,E701,E221,W605 $$myfile; \
        done
