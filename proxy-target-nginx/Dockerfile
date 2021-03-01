FROM openanalytics/r-base

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny', 'rmarkdown', 'highcharter', 'leaflet', 'RColorBrewer', 'scales', 'lattice', 'dplyr', 'DT', 'highcharter', 'tidyr', 'shinyWidgets'), repos='https://cloud.r-project.org/')"

COPY . .

RUN apt-get update && apt-get install -y \
    nginx && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

EXPOSE 3838

ENTRYPOINT ["/entrypoint.sh"]
CMD ["R", "-e", "source('run.R')"]
