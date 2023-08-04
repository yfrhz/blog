rm -rf ./docs/*
echo 'morz.cc' > ./docs/CNAME
hugo
git add .
git commit -m 'change'
git push
