FROM ubuntu:18.04
RUN apt-get update && apt-get install -y sudo
RUN useradd -ms /bin/bash openfpci
RUN usermod -aG sudo openfpci
RUN echo 'openfpic ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /home
USER openfpci
WORKDIR /home/openfpci
RUN  sudo apt-get -y update &&  sudo apt-get -y install git-core  && git clone https://github.com/ParaFEM/OpenFPCI.git
WORKDIR /home/openfpci/OpenFPCI
RUN sudo chmod +x FPCI_install.sh && ./FPCI_install.sh
