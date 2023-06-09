FROM python:3.9 AS builder

ARG AMP_DOC_TOKEN

ENV APM_DOC_TOKEN=${AMP_DOC_TOKEN}
ENV APP_ENV=production
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update && \
    apt-get install \
        curl \ 
        build-essential \
        git \
        libyaml-dev \ 
        parallel -y 

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app
COPY . .

RUN npm install
RUN npx gulp buildPrepare
RUN npx gulp unpackArtifacts
RUN pip install grow --upgrade-strategy eager


RUN npx gulp buildPages --locales 'en'
RUN npx gulp buildFinalize

FROM httpd:2.4 AS final

COPY --from=builder /app/dist/pages/ /usr/local/apache2/htdocs/
RUN mkdir /usr/local/apache2/htdocs/playground
COPY --from=builder /app/dist/playground/ /usr/local/apache2/htdocs/playground/