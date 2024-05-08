
#!/bin/bash

# Input CSV file containing URLs
input_file="Book1.csv"

# Output CSV file
output_file="output.csv"

# Declare an associative array to store headers for each base URL
declare -A base_url_headers

# Declare an associative array to store descriptions for each base URL
declare -A Desc

# Read input file and extract headers from URLs
{
    read
    while IFS=, read -r url description; do
        # Skip processing empty lines
        if [ -z "$url" ]; then
            continue
        fi
        # Extract base URL
        base_url=$(dirname "$url")
        
        # Extract header from URL
        header=$(basename "$url")
        
        # If base URL is not in the array, initialize it with an empty string
        if [ -z "${base_url_headers[$base_url]}" ]; then
            base_url_headers[$base_url]=""
        fi

        # If header does not already exist for this base URL, add it
        if [[ "${base_url_headers[$base_url]}" != *"$header"* ]]; then
            # Add comma if necessary
            if [ ! -z "${base_url_headers[$base_url]}" ]; then
                base_url_headers[$base_url]+=","
            fi
            # Add header
            base_url_headers[$base_url]+="$header"
        fi
        
        # If description is provided, store it under the corresponding header
        if [ ! -z "$description" ]; then
            # Store the description under the corresponding URL and header
            Desc["$base_url/$header"]="$description"
            Desc["$base_url/$header"]=$(echo "${Desc["$base_url/$header"]}" | sed 's/,\([^,]*\),/\1/g')
        fi
    done
} < "$input_file"

# Combine all distinct headers
all_headers=$(printf "%s\n" "${base_url_headers[@]}" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')

# Write data to output file
echo "URL,${all_headers}" > "$output_file"
for base_url in "${!base_url_headers[@]}"; do
    # Start building the row with the base URL
    row="$base_url"
    
    # Loop through each header in all_headers
    for header in ${all_headers//,/ }; do
        # Check if the header exists in base_url_headers[$base_url]
        if [[ "${base_url_headers[$base_url]}" == *"$header"* ]]; then
            content="${Desc["$base_url/$header"]}"
            # Wrap the content in quotes if it contains spaces
            if [[ "$content" == *" "* ]]; then
                content="\"$content\""
            fi
            # Append the content to the row
            row="$row,$content"
        else
            # If the header does not exist, append empty content
            row="$row,"
        fi
    done
    
    # Write the row to the output file
    echo "$row" >> "$output_file"
done

echo "Output CSV file created."
