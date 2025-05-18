# xRDP-OnlyOffice

A minimal Debian-based Docker image providing a remote desktop environment with XRDP and OnlyOffice Desktop Editors. Designed for secure document editing and remote access.

## Features

- **XRDP**: Remote desktop access via RDP protocol.
- **Fluxbox**: Lightweight window manager.
- **OnlyOffice Desktop Editors**: Office suite for editing documents, spreadsheets, and presentations.
- **Custom Entrypoints**: Run custom scripts at container startup.
- **Supervisor**: Manages all services.
- **Background Agent**: Runs silently in the background.

## Usage

### Build the Docker Image

```sh
docker build -f debian.dockerfile -t rdp-onlyoffice2 .
```

### Run the Container

```sh
docker run -d -p 3389:3389 \
  -e XRDP_USER=myuser \
  -e XRDP_PASSWORD=mypassword \
  rdp-onlyoffice2
```

- Connect via RDP to `localhost:3389` using the credentials set above.

## Configuration

Environment variables (with defaults):

- `XRDP_USER` (default: `rdpuser`)
- `XRDP_PASSWORD` (default: `money4band`)
- `LANG` (default: `en_US.UTF-8`)
- `LC_ALL` (default: `C.UTF-8`)
- `CUSTOMIZE` (default: `false`)
- `CUSTOM_ENTRYPOINTS_DIR` (default: `/app/custom_entrypoints_scripts`)
- `AUTO_START_XTERM` (default: `true`)
- `XRDP_PORT` (default: `3389`)
- `RUN_AGENT` (default: `true`) - Enables an agent process at X session start

## Custom Entrypoints

To run custom scripts at startup, mount or add scripts to `/app/custom_entrypoints_scripts` and set `CUSTOMIZE=true`.

Supported script types: `.sh` (bash), `.py` (python3).

## Agent

The system supports running an agent program at the start of the X display session. 
To use your own agent:

1. Create your agent script
2. Mount it to `/app/agent` when running the container
3. Ensure `RUN_AGENT=true` is set

Example:
```sh
docker run -d -p 3389:3389 \
  -e XRDP_USER=myuser \
  -e XRDP_PASSWORD=mypassword \
  -v /path/to/my/agent:/app/agent \
  rdp-onlyoffice2
```

## File Structure

- `debian.dockerfile` - Docker build instructions.
- `supervisord.conf` - Supervisor configuration.
- `conf.d/` - Supervisor program configs.
- `browser_conf/` - Browser supervisor configs.
- `base_entrypoint.sh` - Main entrypoint script.
- `customizable_entrypoint.sh` - Entrypoint for custom startup logic.
- `custom_entrypoints_scripts/` - Place your custom scripts here.

## License

MIT or as specified by upstream components.
