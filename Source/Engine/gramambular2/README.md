# Gramambular2

This is the new version of Gramambular ("gram walk"), a segmentation library
mainly designed for Mandarin Chinese. The library can also be used to
implement input methods, and the many utility methods in the public API
actually reflect that design intent.

The basic principle is a hidden Markov model, with the input (observations)
being Chinese characters and the output (hidden events) being the possible
groups (segmantations). When used for an input method, the input can be
a series of Bopomofo syllables, and the output will be the mostly likely
Chinese characters. The actual computation uses a naive Bayes classifier,
and the required language model is a very simple unigram model.
