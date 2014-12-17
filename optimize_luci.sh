#!/bin/bash

dl_and_extract_apps() {
    wget -qO yuicompressor.jar https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar
    wget -qO compiler.zip http://dl.google.com/closure-compiler/compiler-latest.zip

    unzip -ojqq compiler.zip
    rm -f compiler.zip
}

# The following code is based on:
# https://forum.openwrt.org/viewtopic.php?pid=183795#p183795
#
# We might want to look at modifiying imgopt for our needs
minify_css() {
    for file in $( find "feeds/luci" -iname '*.css' )
    do
        echo "$file"
        java -jar yuicompressor.jar -o "$file-min.css" "$file"
        mv "$file-min.css" "$file"
    done
}

optimize_js() {
    for file in $( find "feeds/luci" -iname '*.js' )
    do
        echo "$file"
        java -jar compiler.jar --compilation_level=SIMPLE_OPTIMIZATIONS --js="$file" --js_output_file="$file-min.js"
        mv "$file-min.js" "$file"
    done
}

dl_and_extract_apps
minify_css
optimize_js

rm -f yuicompressor.jar compiler.jar
