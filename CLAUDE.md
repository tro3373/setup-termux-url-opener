# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Termux-based URL handling and content extraction project that processes URLs to extract Open Graph Protocol (OGP) data and integrate with various services.

## Architecture

### Core Components

1. **termux-url-opener** - Main bash script that:
   - Handles URLs passed from Termux share intent
   - Extracts OGP metadata using the `ogp` binary
   - Logs operations to `/data/data/com.termux/files/home/storage/downloads/termux-url-opener.log`
   - Integrates with Google Keep for saving content
   - Uses X (Twitter) cookies for authentication

2. **cookies.json** - Contains X/Twitter authentication cookies for API access

3. **Documentation** - `hoge.md` and `zen` files document MCP integration with @mizchi/readability

## Development Commands

### Shell Script Linting and Formatting
```bash
# Lint shell scripts
shellcheck -e SC1090,SC2059,SC2155,SC2164,SC2086,SC2162 termux-url-opener

# Format shell scripts  
shfmt -i 2 -ci -s termux-url-opener
```

### Testing the URL Opener
```bash
# Test the script with a URL
./termux-url-opener "https://example.com"

# Check logs
tail -f /data/data/com.termux/files/home/storage/downloads/termux-url-opener.log
```

## Key Implementation Details

### Environment Setup
- Script requires `.env` file in the same directory with `X_COOKIE_JSON` variable
- Uses `termux-chroot` for network operations with DNS resolution (8.8.8.8)
- Depends on `ogp` binary for extracting metadata (currently missing)

### Data Flow
1. URL received → termux-url-opener
2. Process through chroot environment with cookies
3. Extract OGP data (URL, Title, Description, Image)
4. Log results and optionally send to Google Keep

## Dependencies

- **termux-chroot** - Required for network operations
- **jq** - JSON parsing for OGP response
- **ogp** binary - Core component for metadata extraction (needs to be provided)
- **am** (Activity Manager) - Android intent handling

## Notes

- Empty directories (`github/`, `sample/`, `urls/`) suggest planned features or data storage
- MCP integration with @mizchi/readability is documented for web content extraction
- Follows bash best practices with early return patterns and function extraction