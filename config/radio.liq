# Set log level
set("log.level", 3)
set("frame.audio.size", 8192)
set("root.max_latency", 10)
set("buffer.adaptative", true)

# Icecast output settings
icecast_host = getenv("ICECAST_HOST")
icecast_port = int_of_string(getenv("ICECAST_PORT"))
icecast_password = getenv("ICECAST_PASSWORD")
station_name = getenv("STATION_NAME")
station_description = getenv("STATION_DESCRIPTION")
station_url = getenv("STATION_URL")

# Input Harbor Settings
harbor_password = getenv("HARBOR_PASSWORD")
harbor_user = getenv("HARBOR_USER")
harbor_port = getenv("HARBOR_PORT")

# Directory with backup music files
backup_dir = getenv("BACKUP_DIR")

# Create backup playlist
backup_source = playlist.safe(
  mode="randomize",
  backup_dir
)

# Create live input from source
live_source = input.harbor(
  user=harbor_user,
  port=harbor_port,
  password=harbor_password,
  buffer=10.0,
  max=60.0
)

# Buffer the live source
live_source = buffer(live_source)

# Detect silence from live source to trigger failover
silence_detection = blank.strip(
  max_blank=30.0,
  threshold=-50.0,
  live_source
)

# Create a fallback that switches between live and backup
radio = fallback(
  track_sensitive=false,
  [silence_detection,backup_source]
)

# Output to Icecast MP3 stream
output.icecast(
  %mp3,
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
  %fdkaac,
  host=icecast_host,
  port=icecast_port,
  password=icecast_password,
  mount="stream.aac",
  name=station_name,
  description=station_description,
  url=station_url,
  radio
)