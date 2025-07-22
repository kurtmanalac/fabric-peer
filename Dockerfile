FROM hyperledger/fabric-peer:3.1.1

RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files
RUN mkdir -p /app/data/msp

ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files
ENV CORE_PEER_MSPCONFIGPATH=/app/data/msp

WORKDIR /app/data