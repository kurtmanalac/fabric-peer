FROM hyperledger/fabric-ca:1.5.5 as ca-source

FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq && apt-get clean

COPY --from=ca-source /usr/local/bin/fabric-ca-client /usr/local/bin/
COPY --from=ca-source /usr/local/bin/fabric-ca-server /usr/local/bin/

RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files

ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files

WORKDIR /app/data
COPY enroll-peer.sh /enroll-peer.sh
RUN chmod +x /enroll-peer.sh
CMD ["/enroll-peer.sh"]
