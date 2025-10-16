#!/bin/bash
# CARLA container entrypoint script
# Handles initialization and startup configuration

set -e

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check for GPU availability
check_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        log "INFO: GPU detected"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
    else
        log "WARNING: No GPU detected, running in CPU mode (slow performance expected)"
    fi
}

# Setup environment based on config
setup_environment() {
    # Quality level from env var or default
    QUALITY_LEVEL=${CARLA_QUALITY_LEVEL:-Low}
    log "INFO: Setting quality level to: $QUALITY_LEVEL"
    
    # Set world timeout
    if [ -n "$CARLA_TIMEOUT" ]; then
        export CARLA_TIMEOUT_VALUE=$CARLA_TIMEOUT
        log "INFO: World timeout set to: $CARLA_TIMEOUT seconds"
    fi
    
    # Configure for headless if needed
    if [ "$CARLA_RENDER_MODE" = "headless" ]; then
        export SDL_VIDEODRIVER=offscreen
        log "INFO: Running in headless mode"
    fi
}

# Wait for dependencies if needed
wait_for_dependencies() {
    if [ -n "$WAIT_FOR_SERVICES" ]; then
        log "INFO: Waiting for dependent services..."
        for service in $WAIT_FOR_SERVICES; do
            log "INFO: Checking $service..."
            # Simple TCP check
            timeout 30 bash -c "until echo > /dev/tcp/${service%:*}/${service#*:}; do sleep 1; done" 2>/dev/null || {
                log "WARNING: Service $service not available, continuing anyway"
            }
        done
    fi
}

# Main execution
main() {
    log "INFO: Starting CARLA Simulator v${CARLA_VERSION:-0.9.15}"
    
    # Run checks
    check_gpu
    setup_environment
    wait_for_dependencies
    
    # Handle different run modes
    if [ "$1" = "bash" ] || [ "$1" = "sh" ]; then
        log "INFO: Starting shell session"
        exec "$@"
    elif [ "$1" = "python" ] || [ "$1" = "python3" ]; then
        log "INFO: Running Python script"
        exec "$@"
    else
        # Default: start CARLA server
        log "INFO: Starting CARLA server"
        
        # Build command with parameters
        CARLA_CMD="./CarlaUE4.sh"
        
        # Add quality level
        CARLA_CMD="$CARLA_CMD -quality-level=${QUALITY_LEVEL}"
        
        # Add rendering mode
        if [ "$CARLA_RENDER_MODE" = "headless" ]; then
            CARLA_CMD="$CARLA_CMD -RenderOffScreen"
        fi
        
        # Disable sound if specified
        if [ "$CARLA_NO_SOUND" = "true" ]; then
            CARLA_CMD="$CARLA_CMD -nosound"
        fi
        
        # Add custom port if specified
        if [ -n "$CARLA_PORT" ]; then
            CARLA_CMD="$CARLA_CMD -carla-rpc-port=$CARLA_PORT"
        fi
        
        # Add streaming port if specified
        if [ -n "$CARLA_STREAMING_PORT" ]; then
            CARLA_CMD="$CARLA_CMD -carla-streaming-port=$CARLA_STREAMING_PORT"
        fi
        
        # Add any additional arguments
        if [ $# -gt 0 ]; then
            CARLA_CMD="$CARLA_CMD $@"
        fi
        
        log "INFO: Executing: $CARLA_CMD"
        exec $CARLA_CMD
    fi
}

# Trap signals for graceful shutdown
trap 'log "INFO: Received shutdown signal, stopping CARLA..."; exit 0' SIGTERM SIGINT

# Run main function
main "$@"