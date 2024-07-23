# Dockerfile for PHP 8.1 with Apache on Google Cloud Run

This repository contains a Dockerfile to build a Docker image for running a PHP 8.1 application with Apache on Google Cloud Run. The image is configured to expose port 8080, as required by Google Cloud Run, and includes various PHP extensions and system dependencies.

#### To publish:
```sh
docker buildx build --platform linux/amd64 -t samuelfaj/gcr-php-8.1-apache-extensions:amd64 . --push
```