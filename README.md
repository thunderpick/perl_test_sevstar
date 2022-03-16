# Perl test for backend developer

## Before install
Be shure that ```docker``` and ```docker-compose``` packages are installed on your system.

Also ```binutils``` and ```git``` may be needed.

## Run code
  1. ```git clone https://github.com/thunderpick/perl_test_sevstar.git app```
  2. ```cd app```
  3. ```docker build .```
  4. ```docker-compose build```
  5. ```docker-compose up --force-recreate -d```
  6. ```tail -f app.log```

## Basic auth
  Username: ```sevstar```
  
  Password: ```s3cr3t```
