# Indiana Imagery Downloader 2024

A command-line utility for downloading aerial imagery files from the Indiana 2024 statewide imagery dataset.

## Features

- **County-Based Selection** - Select imagery by Indiana county
- **Multiple Product Types** - Download complete imagery packages:
  - **TIF + World Files** - High-quality raster imagery with geolocation data
  - **ECW + World Files** - Compressed raster imagery with geolocation data
  - **SID + World Files** - MrSID compressed imagery with geolocation data
  - **Mosaic Files** - Large-scale combined imagery products
  - **All Product Types** - Download all available formats
- **Smart Product Filtering** - Only shows product types available for selected counties
- **Organized File Structure** - Files are organized by county and product type
- **Resume Capability** - Resume interrupted downloads automatically
- **Batch Processing** - Download multiple counties and products efficiently
- **Progress Monitoring** - Real-time download progress and status reporting

## System Requirements

- Unix-like operating system (Linux, macOS, etc.)
- Bash shell (version 3.0 or later)
- curl command-line utility
- Internet connectivity
- The required CSV dataset file

## Installation and Setup

1. Ensure the CSV dataset file is placed in the same directory as the script
2. Make the script executable:
   ```bash
   chmod +x imagery_downloader.sh
   ```

## Usage

Execute the script and follow the interactive prompts:

```bash
./imagery_downloader.sh
```

### Interactive Process

1. **County Selection** - Select one or more Indiana counties from the available list
2. **Product Type Selection** - Choose from product types available for your selected counties
3. **Download Location** - Specify target directory (default: `./downloads`)
4. **Confirmation** - Review selections and confirm to begin download

### Input Formats

- **Single selection**: `1`
- **Multiple selections**: `1,3,5`
- **Range selections**: `1-4`
- **Combined selections**: `1,3-5,8`

## File Organization

Downloaded files are organized in a hierarchical structure:

```
downloads/
├── CountyName/
│   ├── tif/              # TIF raster files and TFW world files
│   ├── ecw/              # ECW raster files and EWW world files  
│   ├── sid/              # SID raster files and SDW world files
│   └── mosaic/           # Mosaic imagery files
```

## Available Data

Counties and product types are automatically detected from the dataset. The script will display available options based on the current CSV file.

## Data Formats

### Raster Imagery Formats
- **TIF + World Files**: Uncompressed high-quality raster imagery (.tif) with geospatial positioning data (.tfw)
- **ECW + World Files**: Enhanced Compressed Wavelet format (.ecw) with positioning data (.eww) - reduced file size
- **SID + World Files**: MrSID compressed imagery (.sid) with positioning data (.sdw) - optimized compression
- **Mosaic**: Large-scale composite imagery files covering extended geographic areas

### File Characteristics
- **Coordinate System**: Compatible with standard GIS applications
- **File Sizes**: Vary by format and coverage area
- **Coverage**: County-level organization

## System Behavior

### Download Management
- **Resume Support**: Automatically resumes interrupted downloads
- **Duplicate Detection**: Skips files that are already completely downloaded
- **Concurrent Downloads**: Utilizes parallel connections for improved transfer speeds
- **Error Recovery**: Automatic retry on network failures

### Validation
- **File Integrity**: Verifies downloaded file sizes against server specifications
- **Product Availability**: Pre-filters product types based on county data availability
- **Input Validation**: Comprehensive validation of user selections

## Troubleshooting

### Common Issues
- **Missing CSV file**: Ensure the required CSV dataset file is in the script directory
- **Permission errors**: Verify write permissions for the target download directory
- **Network connectivity**: Confirm internet access and DNS resolution
- **Curl availability**: Ensure curl is installed and accessible in system PATH

### Performance Considerations
- **Bandwidth**: Downloads utilize up to 15 concurrent connections
- **Storage**: Ensure adequate disk space for imagery files
- **Interruption**: Use Ctrl+C to safely interrupt downloads; resume by re-running the script

## Technical Support

For technical assistance or to report issues, ensure you have:
- Operating system and version information
- Bash version (`bash --version`)
- Curl version (`curl --version`)
- Error messages or log output
- Steps to reproduce any issues