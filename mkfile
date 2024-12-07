DOCS=reintro
HTML=${DOCS:%=%.html}

all:V: $HTML

%.html: %.md
	pandoc -s -o $target --css https://www.cs.tufts.edu/comp/105-2022f/course.css $prereq

update:V: $HTML
	cp -uv $HTML $HOME/www/dnd

publish:V: update
	rsync -avP $HOME/www/dnd homework:www
