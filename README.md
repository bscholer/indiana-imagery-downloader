# Indiana Imagery Downloader 2024

A user-friendly shell script to download imagery files from the Indiana 2024 imagery footprint dataset.

## Features

- 🎨 **Beautiful ASCII Art Interface** - Eye-catching terminal UI with colors
- 🗺️ **County Selection** - Choose from available Indiana counties
- 📁 **Multiple Product Types** - Download complete imagery packages:
  - **TIF + World Files** - High-quality raster imagery with geolocation
  - **ECW + World Files** - Compressed raster imagery with geolocation
  - **SID + World Files** - MrSID compressed imagery with geolocation
  - **Mosaic Files** - Large-scale combined imagery
  - **All Product Types** - Download everything
- 📂 **Organized Downloads** - Files are organized by county and product type
- ⏸️ **Graceful Interruption** - Handle Ctrl+C cleanly
- 📊 **Download Summary** - See total files and sizes downloaded

## Requirements

- Bash shell (compatible with older versions)
- curl command-line tool
- The `Footprint_2024.csv` file in the same directory

## Usage

1. Make sure `Footprint_2024.csv` is in the same directory as the script
2. Make the script executable:
   ```bash
   chmod +x imagery_downloader.sh
   ```
3. Run the script:
   ```bash
   ./imagery_downloader.sh
   ```
4. Follow the interactive prompts:
   - Select a county from the numbered list
   - Choose a product type to download
   - Specify download directory (default: `./downloads`)
   - Confirm your selection to start downloading

## File Organization

Downloaded files are organized as follows:
```
downloads/
├── CountyName/
│   ├── url_tif/
│   │   ├── file1.tif
│   │   └── file2.tif
│   ├── url_ecw/
│   │   ├── file1.ecw
│   │   └── file2.ecw
│   └── ...
```

## Available Counties

The script automatically detects counties from the CSV file, including:
- Allen
- Fayette
- Hamilton
- Henry
- Huntington
- Lake
- LaPorte
- Monroe
- Porter
- Randolph
- Union
- Wayne

## Product Types Explained

- **TIF + World Files**: High-quality raster imagery (.tif) with geospatial positioning (.tfw) - best quality, larger files
- **ECW + World Files**: Enhanced Compressed Wavelet format (.ecw) with positioning (.eww) - good quality, smaller files  
- **SID + World Files**: MrSID compressed imagery (.sid) with positioning (.sdw) - compressed format
- **Mosaic**: Large-scale combined imagery files covering bigger areas

## Error Handling

The script includes robust error handling:
- Validates CSV file existence
- Checks download directory permissions
- Reports failed downloads with URLs
- Handles network interruptions gracefully

## Example Session

```
Step 1: Select County
Available Counties:
━━━━━━━━━━━━━━━━━━━━
[1] Allen
[2] Fayette
...
Enter county number (1-12): 5

Step 2: Select Product Type
Available Product Types:
━━━━━━━━━━━━━━━━━━━━━━━━
[1] TIF + World Files (High-quality raster + geolocation) - tif
[2] ECW + World Files (Compressed raster + geolocation) - ecw
[3] SID + World Files (MrSID compressed + geolocation) - sid
[4] Mosaic Files (Large-scale combined imagery) - mosaic
[5] All Product Types - all
...
Enter product type number (1-5): 1

Step 3: Set Download Location
Enter download directory path (default: ./downloads): 

Proceed with download? (y/N): y
```

## Support

This script is designed to be compatible with most Unix-like systems and older bash versions. If you encounter any issues, ensure that:
- The CSV file is properly formatted
- You have internet connectivity
- The destination directory is writable
- curl is installed and accessible

Happy downloading! 🚀