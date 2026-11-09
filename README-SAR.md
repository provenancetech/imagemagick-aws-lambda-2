# ImageMagick Lambda Layer for Amazon Linux 2023 AMIs

Static build of ImageMagick for Amazon Linux 2023, packaged as a Lambda layer. 
Bundles ImageMagick 7.1.2-35, including convert, mogrify and identify tools
and support for jpeg, gif, png, tiff, webp, heic and jp2 formats.

This application provides a single output, `LayerVersion`, which points to a
Lambda Layer ARN you can use with Lambda runtimes based on Amazon Linux 2023
(such as `nodejs22.x`, `nodejs24.x`, `python3.13` or `provided.al2023`).
The binaries are built for the x86_64 architecture.

For an example of how to use the layer, check out 
https://github.com/serverlesspub/imagemagick-aws-lambda-2/tree/master/example
