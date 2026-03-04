FROM rocker/r-ver:4.4.2

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Quarto
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.42/quarto-1.6.42-linux-amd64.deb \
    && dpkg -i quarto-1.6.42-linux-amd64.deb \
    && rm quarto-1.6.42-linux-amd64.deb

# Install renv
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Copy lock file and restore
WORKDIR /project
COPY renv.lock renv.lock
RUN R -e "renv::restore(prompt = FALSE)"

# Default command
CMD ["R"]
