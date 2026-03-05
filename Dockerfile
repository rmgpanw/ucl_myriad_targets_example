FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
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

# Install rig (sets up P3M binary repos automatically)
RUN curl -Ls https://github.com/r-lib/rig/releases/download/latest/rig-linux-latest.tar.gz | \
    tar xz -C /usr/local && \
    rig add 4.4.2

# Install Quarto
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.5.55/quarto-1.5.55-linux-amd64.deb \
    && dpkg -i quarto-1.5.55-linux-amd64.deb \
    && rm quarto-1.5.55-linux-amd64.deb

# Install renv, then restore packages to rig's R library
# RENV_ACTIVATE_PROJECT=FALSE prevents renv from redirecting .libPaths()
WORKDIR /project
COPY renv.lock renv.lock
ENV RENV_ACTIVATE_PROJECT=FALSE
RUN R -e "install.packages('renv')" && \
    R -e "renv::restore(library = R.home('library'), prompt = FALSE)"

# Default command
CMD ["R"]
