ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk update && apk add \
	python3 \
	&& rm -rf /var/cache/apk/* \
  && pip3 install pip --upgrade \
  && pip3 install awscli

# copy files and crontab
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY app /usr/src/app
RUN chmod a+x /usr/src/app/run.sh
RUN chmod a+x /usr/src/app/main.sh

CMD ["/usr/src/app/run.sh"]
