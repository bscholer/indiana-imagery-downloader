#!/bin/bash

# Indiana Imagery Downloader 2024
# Interactive script to download imagery files by county and product type

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global arrays
COUNTIES=()
PRODUCT_TYPES=("tif" "ecw" "sid" "mosaic" "all")
PRODUCT_NAMES=("TIF + World Files (High-quality raster + geolocation)" "ECW + World Files (Compressed raster + geolocation)" "SID + World Files (MrSID compressed + geolocation)" "Mosaic Files (Large-scale combined imagery)" "All Product Types")

# Simple header
print_header() {
    echo -e "${GREEN}Indiana Imagery Downloader 2024${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

# Function to check if CSV file exists
check_csv_file() {
    if [[ ! -f "Footprint_2024.csv" ]]; then
        echo -e "${RED}Error: Footprint_2024.csv not found in current directory!${NC}"
        echo "Please ensure the CSV file is in the same directory as this script."
        exit 1
    fi
}

# Function to get unique counties (optimized for large CSV)
get_counties() {
    echo -e "${BLUE}Available Counties:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Clear the array
    COUNTIES=()
    
    echo "Scanning CSV for counties..." >&2
    
    # More efficient: use awk to process only county column and exit early when we have enough data
    local counties=$(awk -F',' '
        NR == 1 { next }  # Skip header
        {
            gsub(/^"/, "", $4)  # Remove leading quote
            gsub(/"$/, "", $4)  # Remove trailing quote
            if ($4 != "" && $4 != "N/A" && $4 != "county" && !seen[$4]) {
                counties[++count] = $4
                seen[$4] = 1
            }
        }
        END {
            for (i = 1; i <= count; i++) {
                print counties[i]
            }
        }
    ' "Footprint_2024.csv" | sort)
    
    local counter=1
    
    while IFS= read -r county; do
        if [[ -n "$county" ]]; then
            echo -e "${YELLOW}[$counter]${NC} $county"
            COUNTIES+=("$county")
            ((counter++))
        fi
    done <<< "$counties"
    
    echo
    echo "Found $((counter-1)) counties"
}

# Function to display product types
get_product_types() {
    echo -e "${BLUE}Available Product Types:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for i in "${!PRODUCT_NAMES[@]}"; do
        local num=$((i+1))
        echo -e "${YELLOW}[$num]${NC} ${PRODUCT_NAMES[$i]} - ${PRODUCT_TYPES[$i]}"
    done
    echo
}

# Function to parse multi-selection input
parse_selection() {
    local input="$1"
    local max_value="$2"
    local -a selections=()
    
    # Replace spaces and split by commas
    IFS=',' read -ra PARTS <<< "${input// /}"
    
    for part in "${PARTS[@]}"; do
        if [[ "$part" =~ ^[0-9]+$ ]] && [[ $part -ge 1 ]] && [[ $part -le $max_value ]]; then
            selections+=("$part")
        elif [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
            # Handle ranges like "1-3"
            local start="${part%-*}"
            local end="${part#*-}"
            if [[ $start -ge 1 ]] && [[ $end -le $max_value ]] && [[ $start -le $end ]]; then
                for ((i=start; i<=end; i++)); do
                    selections+=("$i")
                done
            fi
        fi
    done
    
    # Remove duplicates and sort
    printf '%s\n' "${selections[@]}" | sort -nu
}

# Function to get column numbers for product type (returns main_col:world_col)
get_column_numbers() {
    local product_type="$1"
    case "$product_type" in
        "tif") echo "1:9" ;;      # url_tif:url_tfw
        "ecw") echo "6:10" ;;     # url_ecw:url_eww  
        "sid") echo "16:11" ;;    # url_sid:url_sdw
        "mosaic") echo "13:" ;;   # mosaic (no world file)
        *) echo "0:" ;;
    esac
}

# Function to validate download directory
validate_download_dir() {
    local dir="$1"
    
    # Expand tilde to home directory
    dir="${dir/#\~/$HOME}"
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}Directory doesn't exist. Creating: $dir${NC}" >&2
        mkdir -p "$dir" || {
            echo -e "${RED}Error: Cannot create directory $dir${NC}" >&2
            return 1
        }
    fi
    
    if [[ ! -w "$dir" ]]; then
        echo -e "${RED}Error: Directory $dir is not writable${NC}" >&2
        return 1
    fi
    
    echo "$dir"
}

# Function to download files (single county/product)
download_files() {
    local county="$1"
    local product_type="$2"
    local download_dir="$3"
    
    echo -e "${BLUE}Starting download for County: ${YELLOW}$county${BLUE}, Product: ${YELLOW}$product_type${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Create county subdirectory
    local county_dir="$download_dir/$county"
    mkdir -p "$county_dir"
    
    if [[ "$product_type" == "all" ]]; then
        # Download all product types except "all"
        for prod in "${PRODUCT_TYPES[@]}"; do
            if [[ "$prod" != "all" ]]; then
                download_product_type "$county" "$prod" "$county_dir"
            fi
        done
    else
        download_product_type "$county" "$product_type" "$county_dir"
    fi
}

# Function to download multiple counties and products
download_batch() {
    local counties=()
    local products=()
    local download_dir=""
    
    # Parse arguments: counties -- products -- download_dir
    local mode="counties"
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            if [[ "$mode" == "counties" ]]; then
                mode="products"
            elif [[ "$mode" == "products" ]]; then
                mode="download_dir"
            fi
        elif [[ "$mode" == "counties" ]]; then
            counties+=("$arg")
        elif [[ "$mode" == "products" ]]; then
            products+=("$arg")
        elif [[ "$mode" == "download_dir" ]]; then
            download_dir="$arg"
        fi
    done
    
    local total_combinations=$((${#counties[@]} * ${#products[@]}))
    local current_combination=0
    
    echo -e "${GREEN}Starting batch download of $total_combinations combinations${NC}"
    echo
    
    # Process all combinations sequentially for proper Ctrl+C handling
    for county in "${counties[@]}"; do
        for product in "${products[@]}"; do
            ((current_combination++))
            echo -e "${YELLOW}[${current_combination}/${total_combinations}]${NC} Processing: $county -> $product"
            
            if [[ "$product" == "all" ]]; then
                # Handle "all" products specially
                for prod in "${PRODUCT_TYPES[@]}"; do
                    if [[ "$prod" != "all" ]]; then
                        download_files "$county" "$prod" "$download_dir"
                    fi
                done
            else
                download_files "$county" "$product" "$download_dir"
            fi
        done
        
        echo -e "${GREEN}✓ Completed all downloads for $county${NC}"
        echo
    done
    
    echo -e "${GREEN}Batch download completed!${NC}"
}

# Function to download specific product type
download_product_type() {
    local county="$1"
    local product_type="$2"
    local download_dir="$3"
    
    local column_info=$(get_column_numbers "$product_type")
    local main_col="${column_info%:*}"
    local world_col="${column_info#*:}"
    
    if [[ $main_col -eq 0 ]]; then
        echo -e "${RED}Error: Invalid product type $product_type${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Downloading $product_type files...${NC}"
    
    # Create product type subdirectory
    local product_dir="$download_dir/$product_type"
    mkdir -p "$product_dir"
    
    # Extract URLs for both main files and world files
    local all_urls=""
    
    # Get main files (TIF/ECW/SID/Mosaic)
    local main_urls=$(tail -n +2 "Footprint_2024.csv" | awk -F',' -v county="$county" -v col="$main_col" '
        $4 == county || $4 == "\"" county "\"" {
            gsub(/^"/, "", $col)
            gsub(/"$/, "", $col)
            if ($col != "" && $col != "N/A") print $col
        }
    ')
    
    all_urls="$main_urls"
    
    # Get world files if they exist (TFW/EWW/SDW)
    if [[ -n "$world_col" ]]; then
        local world_urls=$(tail -n +2 "Footprint_2024.csv" | awk -F',' -v county="$county" -v col="$world_col" '
            $4 == county || $4 == "\"" county "\"" {
                gsub(/^"/, "", $col)
                gsub(/"$/, "", $col)
                if ($col != "" && $col != "N/A") print $col
            }
        ')
        if [[ -n "$world_urls" ]]; then
            all_urls="$all_urls"$'\n'"$world_urls"
        fi
    fi
    
    if [[ -z "$all_urls" ]]; then
        echo -e "${YELLOW}No $product_type files found for county: $county${NC}"
        return 0
    fi
    
    local urls="$all_urls"
    
    local count=0
    local total=$(echo "$urls" | wc -l)
    
    echo -e "${BLUE}Found $total files to download${NC}"
    
    # Parallel downloads for efficient transfer
    local max_parallel=15
    
    if [[ $total -eq 1 ]]; then
        # Single file - check if already downloaded
        local url=$(echo "$urls" | head -1)
        local filename=$(basename "$url")
        local filepath="$product_dir/$filename"
        
        if [[ -f "$filepath" ]]; then
            # Check if file is complete
            local remote_size=$(curl -sIL "$url" | grep -i content-length | tail -1 | awk '{print $2}' | tr -d '\r')
            local local_size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null || echo "0")
            
            if [[ "$local_size" == "$remote_size" ]] && [[ "$remote_size" -gt 0 ]]; then
                echo -e "${GREEN}✓ Already complete: $filename${NC}"
                return 0
            elif [[ "$local_size" -gt 0 ]] && [[ "$local_size" -lt "$remote_size" ]]; then
                echo -e "${YELLOW}Resuming: $filename (${local_size}/${remote_size} bytes)${NC}"
                curl -L --fail --show-error --progress-bar \
                    --connect-timeout 5 --max-time 1800 \
                    --retry 2 --retry-delay 1 \
                    --continue-at - --output "$filepath" "$url"
            else
                echo -e "${YELLOW}Re-downloading: $filename (size mismatch)${NC}"
                rm -f "$filepath"
                curl -L --fail --show-error --progress-bar \
                    --connect-timeout 5 --max-time 1800 \
                    --retry 2 --retry-delay 1 \
                    --output "$filepath" "$url"
            fi
        else
            echo -e "${CYAN}Downloading: $filename${NC}"
            curl -L --fail --show-error --progress-bar \
                --connect-timeout 5 --max-time 1800 \
                --retry 2 --retry-delay 1 \
                --output "$filepath" "$url"
        fi
    else
        # Multiple files - use parallel downloads
        echo -e "${YELLOW}Initiating $max_parallel concurrent downloads${NC}"
        echo -e "${CYAN}Processing $total files...${NC}"
        
        # Create a temporary file list for curl (quietly) and check existing files
        local temp_list=$(mktemp)
        local url_count=0
        local skip_count=0
        local resume_count=0
        
        while IFS= read -r url; do
            if [[ -n "$url" && "$url" != "N/A" ]]; then
                local filename=$(basename "$url")
                local filepath="$product_dir/$filename"
                
                if [[ -f "$filepath" ]]; then
                    # File exists - check if it's complete by trying a HEAD request
                    local remote_size=$(curl -sIL "$url" | grep -i content-length | tail -1 | awk '{print $2}' | tr -d '\r')
                    local local_size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null || echo "0")
                    
                    if [[ "$local_size" == "$remote_size" ]] && [[ "$remote_size" -gt 0 ]]; then
                        echo -e "${GREEN}✓ Already complete: $filename${NC}"
                        ((skip_count++))
                        continue
                    elif [[ "$local_size" -gt 0 ]] && [[ "$local_size" -lt "$remote_size" ]]; then
                        echo -e "${YELLOW}Resuming: $filename (${local_size}/${remote_size} bytes)${NC}"
                        ((resume_count++))
                        # Add continue-at option for resume
                        echo "url = \"$url\"" >> "$temp_list"
                        echo "output = \"$filepath\"" >> "$temp_list"
                        echo "continue-at = -" >> "$temp_list"
                        echo "" >> "$temp_list"
                    else
                        # File is corrupted or larger than expected, re-download
                        echo -e "${YELLOW}Re-downloading: $filename (size mismatch)${NC}"
                        rm -f "$filepath"
                        echo "url = \"$url\"" >> "$temp_list"
                        echo "output = \"$filepath\"" >> "$temp_list"
                        echo "" >> "$temp_list"
                    fi
                else
                    # New download
                    echo "url = \"$url\"" >> "$temp_list"
                    echo "output = \"$filepath\"" >> "$temp_list"
                    echo "" >> "$temp_list"
                fi
                ((url_count++))
            fi
        done <<< "$urls"
        
        # Report what we're doing
        local download_count=$((url_count - skip_count))
        if [[ $skip_count -gt 0 ]]; then
            echo -e "${GREEN}Skipped $skip_count already complete files${NC}"
        fi
        if [[ $resume_count -gt 0 ]]; then
            echo -e "${YELLOW}Resuming $resume_count partial downloads${NC}"
        fi
        if [[ $download_count -gt 0 ]]; then
            echo -e "${BLUE}Starting $download_count downloads (max $max_parallel concurrent)${NC}"
            
            # Use curl's config file with progress bars enabled
            curl --config "$temp_list" \
                --parallel --parallel-max $max_parallel \
                --connect-timeout 5 --max-time 1800 \
                --retry 2 --retry-delay 1 \
                --fail --location --progress-bar
            
            echo -e "${GREEN}✓ Download batch completed!${NC}"
        else
            echo -e "${GREEN}✓ All files already downloaded!${NC}"
        fi
        
        # Clean up
        rm -f "$temp_list"
    fi
    
    echo -e "${GREEN}Completed downloading $product_type files for $county${NC}"
    echo
}

# Function to display download summary
show_summary() {
    local download_dir="$1"
    
    echo -e "${BLUE}Download Summary:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -d "$download_dir" ]]; then
        local total_files=$(find "$download_dir" -type f 2>/dev/null | wc -l)
        local total_size=$(du -sh "$download_dir" 2>/dev/null | cut -f1)
        
        echo -e "${GREEN}Total files downloaded: $total_files${NC}"
        echo -e "${GREEN}Total size: $total_size${NC}"
        echo -e "${GREEN}Download location: $download_dir${NC}"
        
        echo
        echo -e "${BLUE}Directory structure:${NC}"
        if command -v tree >/dev/null 2>&1; then
            tree "$download_dir" 2>/dev/null || find "$download_dir" -type d | head -20
        else
            find "$download_dir" -type d | head -20
        fi
    fi
}

# Main function
main() {
    print_header
    
    # Check if CSV file exists
    check_csv_file
    
    # Get user input for counties
    echo -e "${BLUE}Step 1: Select Counties${NC}"
    get_counties
    local max_counties=${#COUNTIES[@]}
    
    if [[ $max_counties -eq 0 ]]; then
        echo -e "${RED}No counties found in the CSV file!${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Enter county numbers (1-$max_counties): ${NC}"
    echo -e "${CYAN}Examples: '1', '1,3,5', '1-3', '1,4-6,8'${NC}"
    read -r county_input
    
    local -a selected_counties=()
    local county_selections_raw
    county_selections_raw=$(parse_selection "$county_input" "$max_counties")
    
    if [[ -z "$county_selections_raw" ]]; then
        echo -e "${RED}Invalid county selection!${NC}"
        exit 1
    fi
    
    while IFS= read -r selection; do
        if [[ -n "$selection" ]]; then
            selected_counties+=("${COUNTIES[$((selection-1))]}")
        fi
    done <<< "$county_selections_raw"
    
    echo -e "${GREEN}Selected counties: ${selected_counties[*]}${NC}"
    echo
    
    # Get user input for product types
    echo -e "${BLUE}Step 2: Select Product Types${NC}"
    get_product_types
    
    echo -e "${CYAN}Enter product type numbers (1-${#PRODUCT_TYPES[@]}): ${NC}"
    echo -e "${CYAN}Examples: '1', '1,2,3', '1-4', '8' (for all)${NC}"
    read -r product_input
    
    local -a selected_products=()
    local product_selections_raw
    product_selections_raw=$(parse_selection "$product_input" "${#PRODUCT_TYPES[@]}")
    
    if [[ -z "$product_selections_raw" ]]; then
        echo -e "${RED}Invalid product type selection!${NC}"
        exit 1
    fi
    
    while IFS= read -r selection; do
        if [[ -n "$selection" ]]; then
            selected_products+=("${PRODUCT_TYPES[$((selection-1))]}")
        fi
    done <<< "$product_selections_raw"
    
    echo -e "${GREEN}Selected product types: ${selected_products[*]}${NC}"
    echo
    
    # Get download directory
    echo -e "${BLUE}Step 3: Set Download Location${NC}"
    echo -e "${CYAN}Enter download directory path (default: ./downloads): ${NC}"
    read -r download_dir
    
    if [[ -z "$download_dir" ]]; then
        download_dir="./downloads"
    fi
    
    download_dir=$(validate_download_dir "$download_dir")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    echo -e "${GREEN}Download directory: $download_dir${NC}"
    echo
    
    # Confirmation
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Download Configuration:${NC}"
    echo -e "${GREEN}  Counties:     ${selected_counties[*]}${NC}"
    echo -e "${GREEN}  Products:     ${selected_products[*]}${NC}"
    echo -e "${GREEN}  Directory:    $download_dir${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Calculate total combinations
    local total_combinations=$((${#selected_counties[@]} * ${#selected_products[@]}))
    echo -e "${BLUE}This will process $total_combinations county/product combinations.${NC}"
    echo
    
    echo -e "${CYAN}Proceed with download? (y/N): ${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Download cancelled.${NC}"
        exit 0
    fi
    
    # Start batch download
    echo
    download_batch "${selected_counties[@]}" -- "${selected_products[@]}" -- "$download_dir"
    
    # Show summary
    echo
    show_summary "$download_dir"
    
    echo -e "${GREEN}Download completed successfully!${NC}"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        printf '%s\n' "${missing_deps[@]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Handle script interruption
cleanup() {
    echo
    echo -e "${YELLOW}Download interrupted. Cleaning up...${NC}"
    exit 130
}

trap cleanup SIGINT SIGTERM

# Check dependencies before starting
check_dependencies

# Run main function
main "$@"