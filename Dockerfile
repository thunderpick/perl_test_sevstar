FROM perl
WORKDIR /root/app
COPY . .
CMD ["cpanm", "--installdeps", "-n", "."]
EXPOSE 80
CMD ["hypnotoad", "-f", "./web.pl"]
