# ------------------------------------------------------------------------------
# Start from the official InterSystems IRIS Community Edition image
# ------------------------------------------------------------------------------
    FROM intersystems/iris-community:latest-cd

    # ------------------------------------------------------------------------------
    # Set a working directory inside the container for your app code
    # ------------------------------------------------------------------------------
    WORKDIR /opt/irisapp
    
    # ------------------------------------------------------------------------------
    # Copy your application files in the container
    # ------------------------------------------------------------------------------
    COPY src src
    COPY iris.script .
    
    # ------------------------------------------------------------------------------
    # Create logs folder
    #   Retrieve logs with: docker exec -it my-iris cat /opt/irisapp/logs/build.log
    # ------------------------------------------------------------------------------
    RUN mkdir -p /opt/irisapp/logs
    
    # ------------------------------------------------------------------------------
    # Import code during the image build by running the iris.script
    # ------------------------------------------------------------------------------
    RUN iris start IRIS && \
        iris session IRIS < iris.script > /opt/irisapp/logs/build.log 2>&1 && \
        iris stop IRIS quietly
    
    # ------------------------------------------------------------------------------
    # Expose the default IRIS ports (same as in docker-compose.yml)
    # ------------------------------------------------------------------------------
    EXPOSE 1972 52773