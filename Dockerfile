FROM rocker/r-ver:4.4.2

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libglpk-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libmbedtls-dev \
    libpng-dev \
    libssl-dev \
    libtiff5-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Quarto
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.5.55/quarto-1.5.55-linux-amd64.deb \
    && dpkg -i quarto-1.5.55-linux-amd64.deb \
    && rm quarto-1.5.55-linux-amd64.deb

# Install renv
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Copy lock file and restore
WORKDIR /project
COPY renv.lock renv.lock
RUN R -e "renv::restore(prompt = FALSE)"

# Default command
CMD ["R"]
