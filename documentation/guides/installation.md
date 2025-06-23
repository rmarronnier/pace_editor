# Installation Guide

This guide will walk you through installing PACE (Point & Click Adventure Creator Editor) on your system.

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10, macOS 10.15, or Linux (Ubuntu 18.04+)
- **Memory**: 4GB RAM
- **Storage**: 500MB free space
- **Graphics**: OpenGL 3.3 compatible graphics card
- **Crystal**: Version 1.16.3 or higher

### Recommended Requirements
- **Operating System**: Windows 11, macOS 12+, or Linux (Ubuntu 20.04+)
- **Memory**: 8GB RAM
- **Storage**: 2GB free space (for projects and assets)
- **Graphics**: Dedicated graphics card with 1GB VRAM
- **Crystal**: Latest stable version

## Installation Methods

### Method 1: Pre-built Binaries (Recommended)

#### Windows
1. Download the latest PACE release from the project's GitHub releases page
2. Extract the ZIP file to your desired location (e.g., `C:\PACE\`)
3. Add the PACE directory to your system PATH:
   - Open System Properties → Advanced → Environment Variables
   - Edit the PATH variable and add your PACE directory
   - Click OK to save changes
4. Open Command Prompt and verify installation: `pace_editor --version`

#### macOS
1. Download the latest PACE release for macOS
2. Extract the archive to `/Applications/PACE/`
3. Add PACE to your PATH by adding this to your `~/.zshrc` or `~/.bash_profile`:
   ```bash
   export PATH="/Applications/PACE:$PATH"
   ```
4. Reload your shell: `source ~/.zshrc`
5. Verify installation: `pace_editor --version`

#### Linux (Ubuntu/Debian)
1. Download the Linux release package
2. Extract to `/opt/pace/`:
   ```bash
   sudo tar -xzf pace_editor-linux.tar.gz -C /opt/
   sudo ln -s /opt/pace/pace_editor /usr/local/bin/pace_editor
   ```
3. Verify installation: `pace_editor --version`

### Method 2: Build from Source

#### Prerequisites
Install the required dependencies:

**Crystal Language:**
```bash
# Ubuntu/Debian
curl -fsSL https://crystal-lang.org/install.sh | sudo bash

# macOS
brew install crystal

# Windows (use WSL or install via scoop)
scoop install crystal
```

**System Dependencies:**

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
  libasound2-dev \
  mesa-common-dev \
  libx11-dev \
  libxrandr-dev \
  libxi-dev \
  xorg-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  build-essential \
  libluajit-5.1-dev \
  pkg-config \
  git \
  cmake
```

**macOS:**
```bash
brew install raylib luajit pkg-config
```

**Windows:**
Install dependencies via MSYS2 or use pre-built libraries.

#### Building PACE

1. **Clone the Repository:**
   ```bash
   git clone [repository-url]
   cd pace_editor
   ```

2. **Install Crystal Dependencies:**
   ```bash
   shards install
   ```

3. **Build PACE:**
   ```bash
   crystal build src/pace_editor.cr --release
   ```

4. **Install Locally:**
   ```bash
   sudo cp pace_editor /usr/local/bin/
   # Or on Windows/macOS, copy to a directory in your PATH
   ```

5. **Verify Installation:**
   ```bash
   pace_editor --version
   ```

## Post-Installation Setup

### First Run Configuration

1. **Create Projects Directory:**
   ```bash
   mkdir ~/pace_projects
   cd ~/pace_projects
   ```

2. **Test Installation:**
   ```bash
   pace_editor --help
   ```

3. **Create Your First Project:**
   ```bash
   pace_editor new my_first_game
   cd my_first_game
   pace_editor
   ```

### IDE Integration (Optional)

#### Visual Studio Code
1. Install the Crystal Language extension
2. Open your PACE project folder
3. Configure build tasks in `.vscode/tasks.json`:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Run PACE",
         "type": "shell",
         "command": "pace_editor",
         "group": "build",
         "presentation": {
           "echo": true,
           "reveal": "always"
         }
       }
     ]
   }
   ```

#### Sublime Text
1. Install the Crystal package via Package Control
2. Add build system in Tools → Build System → New Build System:
   ```json
   {
     "cmd": ["pace_editor"],
     "file_regex": "^(.+):(\\d+):(\\d+): (.+)$",
     "working_dir": "${project_path}"
   }
   ```

## Troubleshooting

### Common Installation Issues

#### "Crystal not found"
**Solution:** Ensure Crystal is installed and in your PATH
```bash
# Check Crystal installation
crystal --version

# If not found, reinstall Crystal following the official guide
```

#### "Cannot find raylib library"
**Solution:** Install raylib dependencies
```bash
# Ubuntu/Debian
sudo apt-get install libraylib-dev

# macOS
brew install raylib

# Or build from source (automatically done in CI)
```

#### "Permission denied" on Linux/macOS
**Solution:** Ensure proper file permissions
```bash
chmod +x pace_editor
sudo chown $USER:$USER pace_editor
```

#### Windows: "DLL not found"
**Solution:** Install Visual C++ Redistributables
1. Download from Microsoft's website
2. Install the latest x64 version
3. Restart your system

### Performance Issues

#### Slow Startup
**Possible Causes:**
- Antivirus scanning the executable
- Insufficient RAM
- Running from slow storage (HDD vs SSD)

**Solutions:**
- Add PACE to antivirus exclusions
- Close unnecessary applications
- Move PACE to SSD storage

#### Graphics Issues
**Possible Causes:**
- Outdated graphics drivers
- Incompatible OpenGL version
- Running on integrated graphics

**Solutions:**
- Update graphics drivers
- Use dedicated GPU if available
- Set environment variable: `export LIBGL_ALWAYS_SOFTWARE=1` (Linux)

### Asset Loading Problems

#### "Cannot load texture" errors
**Solution:** Verify asset file formats
- Use PNG for images with transparency
- Use JPG for background images
- Ensure files are not corrupted
- Check file permissions

#### Sound playback issues
**Solution:** Install audio codecs
```bash
# Ubuntu/Debian
sudo apt-get install ubuntu-restricted-extras

# macOS - usually works out of the box

# Windows - install K-Lite Codec Pack
```

## Updating PACE

### Automatic Updates (Future Feature)
PACE will include an auto-updater in future versions.

### Manual Updates

#### Pre-built Binaries
1. Download the latest release
2. Backup your current installation
3. Replace the old executable with the new one
4. Update any changed configuration files

#### Source Installation
```bash
cd pace_editor
git pull origin main
shards update
crystal build src/pace_editor.cr --release
sudo cp pace_editor /usr/local/bin/
```

## Uninstallation

### Pre-built Installation
1. Remove the PACE directory
2. Remove PACE from your system PATH
3. Delete any desktop shortcuts

### Source Installation
```bash
sudo rm /usr/local/bin/pace_editor
rm -rf ~/pace_editor  # Source directory
```

### Clean Removal
To completely remove PACE and its data:
```bash
# Remove user data (backup first!)
rm -rf ~/.pace_editor
rm -rf ~/pace_projects  # If you want to remove projects too
```

## Getting Help

### Documentation
- [Getting Started Guide](getting-started.md)
- [User Interface Guide](user-interface.md)
- [API Reference](../api/)

### Community Support
- GitHub Issues: Report bugs and request features
- Discord Server: Real-time community help
- Forum: Long-form discussions and tutorials

### Professional Support
- Email: support@pace-editor.com
- Priority support available for commercial users

## Next Steps

After successful installation:
1. Complete the [Getting Started Guide](getting-started.md)
2. Try the [Beginner Tutorial](../tutorials/beginner-tutorial.md)
3. Explore the [Example Projects](../examples/)
4. Join the community and share your creations!

## System-Specific Notes

### Windows Subsystem for Linux (WSL)
PACE can run in WSL2 with GUI support:
1. Install WSL2 with Ubuntu
2. Install X11 server (VcXsrv or similar)
3. Set DISPLAY environment variable
4. Follow Linux installation instructions

### Docker Installation
For containerized deployment:
```dockerfile
FROM crystallang/crystal:latest
RUN apt-get update && apt-get install -y \
    libraylib-dev libluajit-5.1-dev pkg-config
COPY . /app
WORKDIR /app
RUN shards install && crystal build src/pace_editor.cr --release
CMD ["./pace_editor"]
```

### ARM-based Systems (Apple Silicon, Raspberry Pi)
PACE supports ARM architectures:
- macOS Apple Silicon: Use native Crystal builds
- Raspberry Pi: Requires manual compilation
- ARM Linux: Build from source with ARM-optimized flags