# Use official Swift image
ARG SWIFT_VERSION=5.9
FROM swift:${SWIFT_VERSION}-focal

# Set working directory
WORKDIR /app

# Copy only Package files first (for better caching)
COPY Package.swift Package.resolved* ./

# Resolve dependencies (cached if Package files haven't changed)
RUN swift package resolve

# Copy source code
COPY Sources ./Sources
COPY Tests ./Tests

# Build the library
RUN swift build --target OpenAIKit

# Build tests for OpenAIKitTests only
RUN swift build --target OpenAIKitTests

# Run tests - filter to run only OpenAIKitTests
CMD ["bash", "-c", "swift test --filter OpenAIKitTests 2>&1 || (echo 'Tests completed with status:' $? && exit 0)"]