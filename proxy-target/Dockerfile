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

EXPOSE 3838

CMD ["R", "-e", "source('run.R')"]