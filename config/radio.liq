# Set log level
set("log.level", 3)

# Icecast output settings
icecast_host = "icecast"  # Docker service name
icecast_port = 8000
icecast_password = "YOUR_SOURCE_PASSWORD"
station_name = "My Radio Station"
station_description = "My super amazing radio station!"
station_url = "http://cool-radio.ca"
harbor_password="hackme"
harbor_mount="live"
harbor_port=8010

# Directory with backup music files
backup_dir = "/backup_music"

# Create backup playlist that will play when the live source is down
# playlist.safe EOL
backup_source = playlist.safe(
  mode="randomize",
  reload=3600,
  backup_dir
)

# Create live input from Audio Hijack
# Using harbor (TCP) input which Audio Hijack can stream to
live_source = input.harbor(
  harbor_mount, 
  port=harbor_port, 
  password=harbor_password
)

# Detect silence from live source to trigger failover
live_source_with_silence_detection = blank.strip(
  max_blank=60.0, # Switch to backup after 60 seconds of silence
  threshold=-50.0, # Silence detection threshold (dB)
  live_source
)

# Create a fallback that switches between live and backup
radio = fallback(
  track_sensitive=false,
  [live_source_with_silence_detection, backup_source]
)

# Output to Icecast MP3 stream
output.icecast(
  %mp3(bitrate=128),
  host=icecast_host,
  port=icecast_port, 
  password=icecast_password,
  mount="live.mp3",
  name=station_name,
  description=station_description,
  url=station_url,
  radio
)

# Output to Icecast AAC stream
output.icecast(
  %fdkaac(bitrate=96),
  host=icecast_host,
  port=icecast_port, 
  password=icecast_password,
  mount="stream.acc",
  name=station_name,
  description=station_description,
  url=station_url,
  radio
)
