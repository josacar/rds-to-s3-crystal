FROM crystallang/crystal:0.35.0-alpine

WORKDIR /app

ADD shard.yml shard.lock  .

RUN shards install

ADD Makefile .
ADD src src

RUN make crystal

EXPOSE 6666

CMD bin/bootstrap
