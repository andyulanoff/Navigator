swift package \
    --allow-writing-to-directory ./docs \
    generate-documentation --target NavigatorUI \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path NavigatorUI \
    --output-path ./docs
