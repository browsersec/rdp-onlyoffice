# xRDP-OnlyOffice

A minimal Debian-based Docker image providing a remote desktop environment with XRDP, Chromium browser, and OnlyOffice Desktop Editors. Designed for secure, browser-based document editing and remote access.

## Features

- **XRDP**: Remote desktop access via RDP protocol.
- **Fluxbox**: Lightweight window manager.
- **Chromium**: Web browser auto-starts on login.
- **OnlyOffice Desktop Editors**: Office suite for editing documents, spreadsheets, and presentations.
- **Custom Entrypoints**: Run custom scripts at container startup.
- **Supervisor**: Manages all services.

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
  -e STARTING_WEBSITE_URL=https://your-homepage.com \
  rdp-onlyoffice2
```

- Connect via RDP to `localhost:3389` using the credentials set above.

## Configuration

Environment variables (with defaults):

- `XRDP_USER` (default: `rdpuser`)
- `XRDP_PASSWORD` (default: `money4band`)
- `STARTING_WEBSITE_URL` (default: `https://www.google.com`)
- `LANG` (default: `en_US.UTF-8`)
- `LC_ALL` (default: `C.UTF-8`)
- `CUSTOMIZE` (default: `false`)
- `CUSTOM_ENTRYPOINTS_DIR` (default: `/app/custom_entrypoints_scripts`)
- `AUTO_START_BROWSER` (default: `true`)
- `AUTO_START_XTERM` (default: `true`)
- `XRDP_PORT` (default: `3389`)

## Custom Entrypoints

To run custom scripts at startup, mount or add scripts to `/app/custom_entrypoints_scripts` and set `CUSTOMIZE=true`.

Supported script types: `.sh` (bash), `.py` (python3).

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
