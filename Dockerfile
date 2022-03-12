FROM perl
WORKDIR /root/app
COPY . .
EXPOSE 80
CMD ["cpanm --installdeps -n ."]
CMD ["hypnotoad -f ./web.pl"]
# CMD ["tail", "-f", "./app.log"]
