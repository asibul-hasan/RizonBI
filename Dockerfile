# ==============================================================================
# HUGGING FACE SPACES DOCKERFILE — RIZON BI DATA WAREHOUSE PLATFORM
# Module: CI7000 MSc Information Systems Dissertation
# Author: S M HOSNEY ARAFAT RIZON (Student ID: K2554665)
# Supervisor: Dr. Islam Choudhury
# ==============================================================================

FROM node:20-alpine

# Install postgresql-client for direct queries to Aiven Cloud PostgreSQL
RUN apk add --no-cache postgresql-client

# Set working directory
WORKDIR /app

# Configure non-root user (UID 1000) for Hugging Face Spaces security standard
RUN adduser -u 1000 -D user && chown -R user:user /app
USER user

# Copy package descriptors and code
COPY --chown=user:user package.json ./
COPY --chown=user:user server.js ./
COPY --chown=user:user runner.js ./
COPY --chown=user:user dashboard/ ./dashboard/
COPY --chown=user:user presentation/ ./presentation/

# Configure Hugging Face Space Port
ENV PORT=7860
EXPOSE 7860

# Start Live Web & BI API Server
CMD ["node", "server.js"]
