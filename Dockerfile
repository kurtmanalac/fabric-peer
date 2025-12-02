FROM hyperledger/fabric-peer:3.1.1
USER root
RUN apt-get update && apt-get install -y curl jq unzip && apt-get clean

ARG ENROLL_ID
RUN mkdir -p /app/data/fabric-ca-client/$ENROLL_ID/files
ENV CORE_PEER_FILESYSTEMPATH=/app/data/fabric-ca-client/$ENROLL_ID/files

COPY enroll-peer.sh /app/enroll-peer.sh
RUN chmod +x /app/enroll-peer.sh
WORKDIR /app
CMD ["/app/enroll-peer.sh"]
