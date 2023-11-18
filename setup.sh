#!/bin/bash

docker build -t famine_debian .

docker run -v $(pwd):/home/famine -it famine_debian
