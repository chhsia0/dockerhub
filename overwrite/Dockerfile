FROM alpine
RUN mkdir /merged /replaced1 /replaced2 && touch /merged/m1 /replaced1/r1 /replaced2/r2 /replaced3 baz && ln -s /merged /replaced4 && ln -s baz foo && ln -s bar bar && ln -s ../../../../../../../abc xyz
RUN rm -rf /replaced1 /replaced2 /replaced3 /replaced4 foo bar baz xyz && mkdir /replaced3 /replaced4 && touch /merged/m2 /replaced1 bar xyz && ln -s /merged /replaced2 && ln -s bar foo && ln -s baz baz
