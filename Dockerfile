FROM ubuntu:14.04

WORKDIR /root

#Update

RUN apt-get update && \
    apt-get upgrade -y 

#Initial setup (Based on https://github.com/firmadyne/firmadyne)

RUN apt-get install -y wget python python-pip python-lzma busybox-static fakeroot git kpartx netcat-openbsd nmap python-psycopg2 python3-psycopg2 snmp uml-utilities util-linux vlan p7zip-full && \
    git clone --recursive https://github.com/firmadyne/firmadyne.git
    
#Setup Extractor   
RUN	apt-get install -y git-core wget build-essential liblzma-dev liblzo2-dev zlib1g-dev unrar-free && \
    pip install -U pip

RUN git clone https://github.com/firmadyne/sasquatch && \
    cd sasquatch && \
    make && \
    make install && \
    cd .. && \
    rm -rf sasquatch

RUN git clone https://github.com/devttys0/binwalk.git && \
	cd binwalk && \
	./deps.sh --yes && \
	python ./setup.py install && \
	pip install git+https://github.com/ahupp/python-magic && \
	pip install git+https://github.com/sviehb/jefferson && \
	cd .. && \
	rm -rf binwalk

#Setup QEMU

RUN	apt-get install -y qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils


#Setup Binaries

RUN	cd ./firmadyne && ./download.sh && \
	sed -i  's/#FIRMWARE_DIR=\/home\/vagrant\/firmadyne/FIRMWARE_DIR=\/root\/firmadyne/g' firmadyne.config 
	
	
#Setup Database
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
	echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
	apt-get update && apt-get install -y python-software-properties software-properties-common postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3
					 
USER postgres

RUN	cd /tmp &&\
	 /etc/init.d/postgresql start &&\
	 psql --command "CREATE user firmadyne WITH PASSWORD 'firmadyne';" && \
	 createdb -O firmadyne firmware && \
	 wget -O schema https://raw.githubusercontent.com/firmadyne/firmadyne/master/database/schema && \
	 psql -d firmware < schema && \
	/etc/init.d/postgresql stop


# Start
USER root
ENV USER root
ENTRYPOINT su - postgres -c "/etc/init.d/postgresql start" &&\
	   /bin/bash



	
