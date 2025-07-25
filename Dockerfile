FROM elixir:1.18.4-otp-26-alpine AS build

ENV MIX_ENV="prod"
ENV ERL_AFLAGS="-kernel shell_history enabled false +S 1 +P 110000 +A 16 +sbwt none +sbwtdcpu none +sbwtdio none"

RUN apk update && apk add --no-cache build-base

WORKDIR /app

RUN mix do local.hex --force, local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY priv priv
COPY test test
COPY lib lib
COPY .formatter.exs .formatter.exs
COPY start.sh start.sh

RUN mix do compile, release

FROM alpine:3.22.0 AS app

ENV MIX_ENV="prod"
ENV ERL_AFLAGS="-kernel shell_history enabled false +S 1 +P 110000 +A 16 +sbwt none +sbwtdcpu none +sbwtdio none"

RUN apk update && apk add --no-cache ncurses-libs libstdc++

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/$MIX_ENV/rel/rinha_de_backend ./
COPY --from=build --chown=nobody:nobody /app/start.sh ./start.sh

ENV HOME=/app

CMD ["sh", "./start.sh"]
