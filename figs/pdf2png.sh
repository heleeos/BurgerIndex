#! /bin/bash
for file in ./*.pdf
do
	sips -s format png $file --out ${file/%.pdf/.png};
done