FROM node:12-buster as frontend-build

# Update default packages
RUN apt-get update

# Get packages
RUN apt-get install -y \
    build-essential \
    curl

# Install rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        libc6-dev \
        wget \
        ; \
    \
    url="https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    wget "$url"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain nightly; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version; \
    \
    apt-get remove -y --auto-remove \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*;


# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# ENV PATH="/root/.cargo/bin:${PATH}"

# Install wasm pack
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh 

# Install vite-plugin-rust from source cause fuck em
RUN git clone https://github.com/gliheng/vite-plugin-rust.git
WORKDIR /vite-plugin-rust
RUN npm install
RUN npm run build
RUN npm link

# FRONTEND

WORKDIR /pw3-frontend
COPY pw3-frontend ./
RUN npm install
RUN npm run build
RUN npm link vite-plugin-rust

FROM nginx:mainline


WORKDIR /app
COPY --from=frontend-build /pw3-frontend/dist /usr/share/nginx/html/