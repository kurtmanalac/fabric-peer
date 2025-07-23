FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq && apt-get clean

# RUN mkdir -p /app/data/config
RUN mkdir -p /app/data/files
RUN mkdir -p /app/data/msp
# RUN chown -R root:root /app
# RUN chmod -R 755 /app

# ENV PATH="/usr/local/bin:$PATH"
# ENV FABRIC_CFG_PATH=/app/data/config
ENV CORE_PEER_FILESYSTEMPATH=/app/data/files
ENV CORE_PEER_MSPCONFIGPATH=/app/data/${ENROLL_ID}/msp

WORKDIR /app
COPY enroll-peer.sh /app/enroll-peer.sh
RUN chmod +x /app/enroll-peer.sh
CMD ["/app/enroll-peer.sh"]
