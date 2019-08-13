# Purpose
Run Gimp in a container

# Requirements
* MacOS
* Docker
* XQuartz

# Usage
I wrote a Makefile to handle the life cycle of images and containers, the
syntax is as follows:

## Getting help
    $ make help

## Building the image
    $ make build

## Running the container
    $ make run

By default the saved files are stored in ~/container/gimp on your host, you can
change the directory by overriding the *VOL_SHARE* variable, for example:

    $ make VOL_SHARE=~/gimp run

## Getting a shell access to the running container
    $ make shell

## Stopping the container
    $ make stop

## Removing the image
    $ make clean
