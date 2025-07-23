FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq && apt-get clean

# COPY --from=ca-source /usr/local/bin/fabric-ca-client /usr/local/bin/
# COPY --from=ca-source /usr/local/bin/fabric-ca-server /usr/local/bin/

# RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files
RUN mkdir -p /app/data/msp

# ENV PATH="/usr/local/bin:$PATH"
# ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files
ENV CORE_PEER_MSPCONFIGPATH=/app/data/msp

WORKDIR /app/data
COPY enroll-peer.sh /enroll-peer.sh
RUN chmod +x /enroll-peer.sh
# CMD ["/enroll-peer.sh"]
