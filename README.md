# Dockerfile for PHP 8.1 with Apache on Google Cloud Run

This repository contains a Dockerfile to build a Docker image for running a PHP 8.1 application with Apache on Google Cloud Run. The image is configured to expose port 8080, as required by Google Cloud Run, and includes various PHP extensions and system dependencies.

#### To publish:
```sh
docker buildx build --platform linux/amd64 -t samuelfaj/gcr-php-8.1-apache-extensions:amd64 . --push
```
#### Security rebuild (CVE-2026-109618 / CVE-2026-109619)

PHP 8.1 is end-of-life and has no official 8.1 release for these critical RCE fixes. The Dockerfile pins the official `php:8.1.34-apache-bookworm` image by digest and rebuilds PHP with the php-src backport in `patches/`. GitHub Actions builds, smoke-tests and publishes it as `ghcr.io/samuelfaj/gcr-php-8.1-apache-extensions:8.1.34-cve-2026-109618`.
