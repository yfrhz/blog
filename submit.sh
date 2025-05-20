rm -rf ./docs/*
echo 'blog.morz.cc' > ./docs/CNAME
hugo
git commit -am 'change'
git push
