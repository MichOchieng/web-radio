# Web Radio Streaming Setup Guide

This is an overview of the streaming infrastructure design for an internet radio station using Docker, Caddy, Icecast2, and Liquidsoap.

## Requirements

- Docker and Docker Compose
- Caddy v2.6+
- Icecast2 (run in Docker)
- Liquidsoap (run in Docker)
- Audio Hijack or similar broadcast software

## System Architecture

The system consists of the following components:

1. **Audio Source**: Audio Hijack or similar software sending a stream to Liquidsoap
2. **Liquidsoap**: Handles stream processing, silence detection, and fallback to backup music
3. **Icecast2**: Streaming server that delivers the content to listeners
4. **Caddy**: Reverse proxy that handles SSL, authentication, and routing

![Stream Architecture Diagram](/public/stream.png)

## Docker Configuration

The setup leverages Docker Compose to orchestrate the services:

- **Icecast Container**: Handles the streaming server functionality
    - Exposes port 8000 internally
    - Configured with environment variables for passwords
    - Mounts external configuration and log directories
- **Liquidsoap Container**: Manages audio processing and fallback logic
    - Depends on the Icecast container
    - Exposes port 8010 for the incoming audio stream
    - Mounts the Liquidsoap script and backup music directory

These containers communicate through a dedicated Docker network.

## Icecast Configuration

The Icecast configuration handles:

- **Stream Mounts**: Two mount points are configured:
    - `/live.mp3` for MP3 format streaming
    - `/stream.aac` for AAC format streaming
- **Authentication**:
    - Source password for Liquidsoap to connect
    - Admin password for web admin panel access
- **Networking**:
    - Listens on port 8000 for HTTP connections
    - Optional SSL socket on port 8443

## Liquidsoap Configuration

Liquidsoap provides these key functions:

- **Harbor Input**: Listens on port 8010 for incoming streams from Audio Hijack
- **Silence Detection**: Monitors the live stream for silence
    - If silence exceeds 60 seconds, switches to backup source
    - Threshold set to -50dB to detect true silence
- **Backup System**: Provides a reliable fallback system
    - Uses a randomized playlist from the backup directory
    - If playlist fails, falls back to an emergency track
- **Dual Format Output**: Sends the stream to Icecast in both formats
    - MP3 stream at 128kbps
    - AAC stream at 96kbps

## Caddy Setup

Caddy serves as the frontend for listeners and handles:

- **SSL/TLS**: Automatic HTTPS certificate management
- **Stream Routing**:
    - `/mp3` route serves the MP3 stream
    - `/aac` route serves the AAC stream
    - Root path `/` redirects to the MP3 stream
- **Security**:
    - Admin panel access restricted to specific IP range (ex: 142.207.50.0/24)
    - Proper headers for streaming (Range, proxy configuration, etc.)
- **Proxy Configuration**:
    - Uses HTTP/1.1 for compatibility with streaming
    - Disables buffering for real-time streaming
    - Sets appropriate headers for cross-origin access

## Security Considerations

- Passwords are stored as environment variables, not in configuration files
- Admin access is restricted by IP
- HTTPS is enforced for all connections
- Authentication is required for source connections

## Monitoring and Maintenance

- Icecast provides a status page for monitoring active listeners
- Logs are stored in mounted volumes for persistence
- Container health can be monitored via Docker

## Stream Client Configuration

Audio Hijack (or similar software) should be configured to:

- Connect to the server's public IP or hostname
- Use port 8010 (Liquidsoap's harbor input)
- Use the mount point "live" (without extension)
- Authenticate with the harbor password
- Stream in MP3 format (128kbps or higher recommended)

## Troubleshooting Tips

- Check Docker container logs for issues:
    - `docker-compose logs liquidsoap`
    - `docker-compose logs icecast`
- Verify stream connection with:
    - `curl -I http://localhost:8000/live.mp3`
- Test playlist playback by stopping the live source
- Monitor silence detection by temporarily muting the input