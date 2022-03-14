FROM perl
WORKDIR /root/app
COPY . .
EXPOSE 80
RUN cpanm --installdeps -n .
