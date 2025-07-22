FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq wget tar && apt-get clean
RUN wget https://github.com/hyperledger/fabric-ca/releases/download/v1.5.5/hyperledger-fabric-ca-linux-amd64-1.5.5.tar.gz && \
    tar -xzf hyperledger-fabric-ca-linux-amd64-1.5.5.tar.gz && \
    cp fabric-ca-client /usr/local/bin/ && \
    chmod +x /usr/local/bin/fabric-ca-client && \
    rm -rf fabric-ca-client fabric-ca-server *.tar.gz
    
RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files

ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files

WORKDIR /app/data
COPY enroll-peer.sh /enroll-peer.sh
RUN chmod +x /enroll-peer.sh
CMD ["/enroll-peer.sh"]
