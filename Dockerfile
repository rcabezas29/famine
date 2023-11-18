FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y gcc make git

RUN apt install -y file readelf xxd elfutils

RUN mkdir /home/famine

COPY ./ /home/famine

CMD ["bash"]
