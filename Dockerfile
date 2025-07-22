FROM hyperledger/fabric-peer:3.1.1

RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files

ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files

WORKDIR /app/data
COPY enroll-peer.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/enroll-peer.sh

CMD ["/usr/local/bin/enroll-peer.sh"]
