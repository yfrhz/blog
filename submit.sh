rm -rf ./docs/*
echo 'blog.morz.cc' > ./docs/CNAME
hugo
git add .
git commit -m 'change'
git push
