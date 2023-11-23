FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y gcc make git

RUN apt install -y file xxd binwalk

RUN mkdir /home/famine

COPY ./ /home/famine

WORKDIR /home/famine

CMD ["bash"]
