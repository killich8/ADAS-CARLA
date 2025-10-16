#!/usr/bin/env python3
"""
Health check script for CARLA simulator container.
Verifies that CARLA is running and responsive.
"""

import sys
import os
import time
import carla
from typing import Optional


def check_carla_health(
    host: str = "localhost", 
    port: int = 2000,
    timeout: float = 5.0
) -> bool:
    """
    Check if CARLA server is healthy and responsive.
    
    Args:
        host: CARLA server hostname
        port: CARLA server port
        timeout: Connection timeout in seconds
    
    Returns:
        True if healthy, False otherwise
    """
    try:
        # Try to connect to CARLA
        client = carla.Client(host, port)
        client.set_timeout(timeout)
        
        # Get server version - basic connectivity check
        version = client.get_server_version()
        print(f"CARLA server version: {version}")
        
        # Try to get the world - more comprehensive check
        world = client.get_world()
        if world is None:
            print("ERROR: Could not get world from CARLA server")
            return False
        
        # Get some basic info to ensure server is fully operational
        map_name = world.get_map().name
        print(f"Current map: {map_name}")
        
        # Check if we can get actors (another sign of healthy server)
        actors = world.get_actors()
        print(f"Number of actors in world: {len(actors)}")
        
        # Get server fps - useful for performance monitoring
        snapshot = world.get_snapshot()
        if snapshot:
            server_fps = 1.0 / snapshot.timestamp.delta_seconds if snapshot.timestamp.delta_seconds > 0 else 0
            print(f"Server FPS: {server_fps:.2f}")
            
            # Warn if FPS is too low (but don't fail health check)
            if server_fps < 10 and server_fps > 0:
                print(f"WARNING: Low server FPS detected: {server_fps:.2f}")
        
        print("Health check: PASS")
        return True
        
    except carla.TCPConnectionError as e:
        print(f"ERROR: Cannot connect to CARLA server at {host}:{port}")
        print(f"Details: {str(e)}")
        return False
    except TimeoutError as e:
        print(f"ERROR: Connection timeout after {timeout} seconds")
        print(f"Details: {str(e)}")
        return False
    except Exception as e:
        print(f"ERROR: Unexpected error during health check")
        print(f"Details: {str(e)}")
        return False


def main():
    """Main health check execution."""
    # Get configuration from environment variables
    host = os.getenv("CARLA_HOST", "localhost")
    port = int(os.getenv("CARLA_PORT", "2000"))
    timeout = float(os.getenv("CARLA_HEALTHCHECK_TIMEOUT", "5.0"))
    retry_count = int(os.getenv("CARLA_HEALTHCHECK_RETRIES", "3"))
    retry_delay = float(os.getenv("CARLA_HEALTHCHECK_RETRY_DELAY", "2.0"))
    
    print(f"Starting CARLA health check for {host}:{port}")
    print(f"Config: timeout={timeout}s, retries={retry_count}, retry_delay={retry_delay}s")
    
    # Try multiple times with delay between attempts
    for attempt in range(1, retry_count + 1):
        print(f"\nAttempt {attempt}/{retry_count}")
        
        if check_carla_health(host, port, timeout):
            # Success!
            sys.exit(0)
        
        # If not last attempt, wait before retrying
        if attempt < retry_count:
            print(f"Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)
    
    # All attempts failed
    print(f"\nHealth check FAILED after {retry_count} attempts")
    sys.exit(1)


if __name__ == "__main__":
    main()