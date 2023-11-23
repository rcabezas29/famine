FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y gcc make git

RUN apt install -y nasm
RUN apt install -y file xxd binwalk binutils
RUN mkdir /home/famine
COPY ./ /home/famine
WORKDIR /home/famine
CMD ["bash"]
