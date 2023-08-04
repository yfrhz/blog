rm -rf ./docs/*
echo 'morz.cc' > ./docs/CNAME
hugo build
git add .
git commit -m 'change'
git push
