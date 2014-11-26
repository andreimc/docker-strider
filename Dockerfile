FROM ubuntu:14.04
MAINTAINER Andrei Miulescu<lusu777@gmail.com>

ENV STRIDER_TAG 1.6.0-pre.2
ENV STRIDER_REPO https://github.com/Strider-CD/strider

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

RUN apt-get update && \
  apt-get install -y git supervisor python-pip nodejs npm curl build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev && \
  update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10 && \
  pip install supervisor-stdout && \
  sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf
RUN apt-get clean

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 2.1.5
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN bash -l -c 'rbenv global 2.1.5; gem install bundler;'

ADD sv_stdout.conf /etc/supervisor/conf.d/

VOLUME /home/strider/.strider
RUN mkdir -p /home/strider && mkdir -p /opt/strider
RUN adduser --disabled-password --gecos "" --home /home/strider strider
RUN chown -R strider:strider /home/strider
RUN chown -R strider:strider /opt/strider
RUN ln -s /opt/strider/src/bin/strider /usr/local/bin/strider
USER strider
ENV HOME /home/strider

RUN git clone --branch $STRIDER_TAG --depth 1 $STRIDER_REPO /opt/strider/src && \
  cd /opt/strider/src && npm install && npm run postinstall && npm run build
COPY start.sh /usr/local/bin/start.sh
ADD strider.conf /etc/supervisor/conf.d/strider.conf
EXPOSE 3000
USER root
CMD ["bash", "/usr/local/bin/start.sh"]
