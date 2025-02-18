# Build for AMD64 explicitly (especially if you're on Apple Silicon)
# docker build --platform=linux/amd64 -t local/vscode:test .

FROM wandelbotscb/vscode:latest

USER root

# Install Docker CLI, Git, cURL, unzip
RUN apt-get update && apt-get install -y \
    docker.io \
    git \
    curl \
    unzip \
 && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o "/tmp/awscliv2.zip" \
    && unzip /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

EXPOSE 8443
