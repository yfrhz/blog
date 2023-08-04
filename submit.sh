rm -rf ./doc/*
echo 'morz.cc' > ./doc/CNAME
hugo
git add .
git commit -m 'change'
git push
