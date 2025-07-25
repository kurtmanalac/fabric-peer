FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq unzip && apt-get clean

RUN mkdir -p /app/data/files

ENV CORE_PEER_FILESYSTEMPATH=/app/data/files

WORKDIR /app
COPY enroll-peer.sh /app/enroll-peer.sh
RUN chmod +x /app/enroll-peer.sh
CMD ["/app/enroll-peer.sh"]
