#Use the current Ubuntu LTS release
FROM ubuntu:16.04
MAINTAINER Chris Hilsdon <chrish@xigen.co.uk>

# dpkg-preconfigure error messages fix
# http://stackoverflow.com/a/31595470
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update the apt-get repository
RUN apt-get update

# Install necessary tools
RUN apt-get install -y nano wget dialog net-tools libreadline6 libreadline6-dev sudo apt-utils

# Install Nginx mainline
ADD nginx.list /etc/apt/sources.list.d/nginx.list
RUN wget -q -O- http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
RUN sudo apt-get update

# Download and Install Nginx
RUN apt-get install -y nginx

RUN nginx -v

# Define working directory.
#WORKDIR /etc/nginx

#VOLUME ["/etc/nginx"]

# Expose ports.
EXPOSE 80 443

# Define default command.
ENTRYPOINT service nginx restart && bash;
