# ImageMagick for AWS Lambda

Scripts to compile ImageMagick utilities for AWS Lambda instances powered by Amazon Linux 2023, such as the `nodejs22.x`, `nodejs24.x`, `python3.13` or `provided.al2023` runtimes.

Amazon Linux instances for Lambda no longer contain system utilities, so `convert`, `mogrify` and `identify` from the [ImageMagick](https://imagemagick.org) package are no longer available.

> **Compatibility:** the binaries are compiled on Amazon Linux 2023 (glibc 2.34) for `x86_64`, which covers every currently supported Lambda runtime. The remaining Amazon Linux 2 runtimes (`python3.10`/`python3.11`, `java8.al2`/`java11`/`java17` on AL2, `provided.al2`) and `arm64` functions are **not** supported - use layer version 1.x for those.

## PTI Specific Usage
First, make sure you have the proper amazon credentials setup. Then run: 
```
make all && make deploy DEPLOYMENT_BUCKET=pti-<ENV>-cluster-assets-bucket STACK_NAME=serverlessrepo-pti-<ENV>-image-magick-lambda-layer2
```

## Usage

Absolutely the easiest way of using this is to pull it directly from the AWS Serverless Application repository into a CloudFormation/SAM application, or deploy directly from the Serverless Application Repository into your account, and then link as a layer.

For more information, check out the [image-magick-lambda-layer](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:145266761615:applications~image-magick-lambda-layer) application in the Serverless App Repository.

For manual deployments and custom builds, read below...

## Prerequisites

* Docker desktop
* Unix Make environment
* AWS command line utilities (just for deployment)

## Compiling the code

* start Docker services
* `make all`

There are two `make` scripts in this project.

* [`Makefile`](Makefile) is intended to run on the build system, and just starts a Docker container matching the Amazon Linux 2023 environment for Lambda runtimes to compile ImageMagick using the second script.
* [`Makefile_ImageMagick`](Makefile_ImageMagick) is the script that will run inside the container, and actually compile binaries. 

The output will be in the `result` dir.

### Configuring the build

By default, this compiles a version expecting to run as a Lambda layer from `/opt`. You can change the expected location by providing a `TARGET` variable when invoking `make`.

The build runs inside the container defined by [`Dockerfile`](Dockerfile), based on `public.ecr.aws/amazonlinux/amazonlinux:2023`. Useful overrides when invoking `make`:

* `BASE_IMAGE=<image>` - compile against a different Amazon Linux base image
* `DOCKER_IMAGE=<tag>` - change the tag given to the locally built image
* `DOCKER_PLATFORM=linux/arm64` - build for arm64 functions instead of the default `linux/amd64`. If you do, update `CompatibleArchitectures` in [`template.yaml`](template.yaml) too.

Modify the versions of libraries or ImageMagick directly in [`Makefile_ImageMagick`](Makefile_ImageMagick).

### Experimenting

* `make bash` to open an interactive shell with all the build directories mounted
* `make libs` to make only the libraries, useful to test building additional libraries without building ImageMagick itself

### Bundled libraries

This is not a full-blown ImageMagick setup you can expect on a regular Linux box, it's a slimmed down version to save space that works with the most common formats. You can add more formats by including another library into the build process in [`Makefile_ImageMagick`](Makefile_ImageMagick).

These libraries are currently bundled:

* libpng
* libtiff
* libjpeg
* openjpeg2
* libwebp
* libbzip2
* libde265 and libheif (HEIC/HEIF)
* Little CMS 2 (colour management)

Current versions, all pinned at the top of [`Makefile_ImageMagick`](Makefile_ImageMagick):

| Component | Version |
| --- | --- |
| ImageMagick | 7.1.2-35 |
| libpng | 1.6.59 |
| libjpeg | 9f |
| libtiff | 4.7.2 |
| openjpeg2 | 2.5.4 |
| libwebp | 1.6.0 |
| libbzip2 | 1.0.8 |
| libheif | 1.23.7 |
| libde265 | 1.1.3 |
| Little CMS 2 | 2.20 |

Every pull request rebuilds the layer in CI ([`ci.yml`](.github/workflows/ci.yml)) and runs the resulting binaries inside the Amazon Linux 2023 runtime image, so a version bump that no longer compiles or no longer runs on Lambda is caught before merge.

## Deploying to AWS as a layer

Run the following command to deploy the compiled result as a layer in your AWS account.

```
make deploy DEPLOYMENT_BUCKET=<YOUR BUCKET NAME>
```

### configuring the deployment

By default, this uses imagemagick-layer as the stack name. Provide a `STACK_NAME` variable when
calling `make deploy` to use an alternative name.

### example usage

An example project is in the [example](example) directory. It sets up two buckets, and listens to file uploads on the first bucket to convert and generate thumbnails, saving to the second bucket. You can deploy it from the root Makefile using:

```
make deploy-example DEPLOYMENT_BUCKET=<YOUR BUCKET NAME>
```



## Info on scripts

For more information, check out:

* https://imagemagick.org/script/install-source.php
* http://www.linuxfromscratch.org/blfs/view/cvs/general/imagemagick.html

## Author

Gojko Adzic <https://gojko.net>

## License

* These scripts: [MIT](https://opensource.org/licenses/MIT)
* ImageMagick: https://imagemagick.org/script/license.php
* Contained libraries all have separate licenses, check the respective web sites for more information
