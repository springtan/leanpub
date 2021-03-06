#!/bin/bash

printf "  *** knit file, fix latex, and move to  *** \n\n"

cd ../labs/$1

## Before we knit we create  temporary file
## and add a link to the Rmd markdown after every subsection
## but only if not an exercise file

if [[ ! "$2" =~ "_exercises" ]] && [[ $2 != "introduction" ]] 
then
	linetoadd="The R markdown document for this section is available \[here]\(https\:\/\/github.com\/genomicsclass\/labs\/tree\/master\/$1\/$2.Rmd\)."

	sed '/^## /a \
\'$'\n@@@@@@
' $2.Rmd | sed 's/@@@@@@/'"$linetoadd"'/' > $2-tmp.Rmd
else
	cp $2.Rmd $2-tmp.Rmd
fi

## Now we knit
Rscript --no-init-file -e "library(knitr); knit('$2-tmp.Rmd', quiet=TRUE)"

### Here we are converting the $ used by latex to $$ used by jekyll

sed 's/\$\$/@@@@/g' $2-tmp.md |
    sed 's/ \$/ @@@@/g' |
    sed 's/\$ /@@@@ /g' |
    sed 's/\$\./@@@@\./g' |
    sed 's/\$,/@@@@,/g' |
    sed 's/\$:/@@@@:/g' |
    sed 's/\$?/@@@@?/g' |
	sed 's/\$-/@@@@-/g' |
    sed 's/(\$/(@@@@/g' |
    sed 's/\$)/@@@@)/g' |
    sed 's/^\$/@@@@/g' |
    sed 's/\$$/@@@@/g' |
    sed 's/:\$/:@@@@/g' |
    sed 's/@@@@/\$\$/g' |
    sed 's/\$\$/{\$\$}/g' |
    sed 's/(figure\//(images\/R\//g' |
    sed 's/\"figure\//\"images\/R\//g'> $2.md

rm $2-tmp.Rmd
rm $2-tmp.md
  
### Here we are converting the $$ used by latex and jekyll to
### in {$$} {\$$} used by leanpub
  
awk '
BEGIN {count = 0;}
{
gsub(/\{\$\$\}/,"@@@@\{\$\$\}@@@@");
n=split($0,a,"@@@@")
line = "";
for (i=1;i<=n;++i){
	if(a[i]=="\{\$\$\}") {
		++count;
		if(count==2) { 
			a[i] = "\{/\$\$\}"; 
			count=0
		}
	}
	line=(line a[i])
}
print line;
}
' $2.md > $2-tmp.md

rm $2.md

### If exercises add the A>
if [[ "$2" =~ "_exercises" ]]
then
	awk '
	BEGIN {start=0; flag=1}
	{
	if ($0 ~ "## Exercises") { start = 1 } 
	if ($0 ~ "```r")
	{
		flag=0
		print $0
	}
	else
	{
		if (start && flag) print "A>" $0
		else 
		{
			print $0
			if ($0 ~ "```") flag=1
		}
	}
}
	' $2-tmp.md > $2.md
	rm $2-tmp.md
else 
	mv $2-tmp.md $2.md
fi


##mv to leanpub and move over the final md

cd ../../leanpub
mv ../labs/$1/$2.md ./manuscript

## move the images into leanpub directory and add to github

imgcount=`ls -1 ../labs/$1/figure/$2* 2> /dev/null | wc -l`
 
if [ $imgcount -gt 0 ]
then
mv ../labs/$1/figure/$2* manuscript/images/R/
fi


printf "  *** add new files to BOOK, commit and push *** \n\n"

cd manuscript
git add $2.md

if [ $imgcount -gt 0 ]
then
git add images/R/$2*
fi

git commit -am "adding $2 to book" > /dev/null

printf "\n  *** done! *** \n\n"

