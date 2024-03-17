import json
from datetime import datetime

# Function to check if the end date is before or equal to a given date
def is_before_or_equal(end_date_str, target_date_str):
    end_date = datetime.strptime(end_date_str, "%Y-%m-%dT%H:%M:%SZ")  # Parse end_date_str
    target_date = datetime.strptime(target_date_str, "%Y-%m-%d %H:%M:%S")  # Parse target_date_str
    return end_date <= target_date

# Function to format date string
def format_date(date_str):
    date_obj = datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%SZ")
    return date_obj.strftime("%Y-%m-%d %H:%M:%S")

# Path to the input and output files
input_file_path = "heartRateData.json"
output_file_path = "filtered_output.json"

# Target date
target_date_str = "2024-02-20 07:26:31"

# Read JSON data from the input file
with open(input_file_path, "r") as f:
    data = json.load(f)

# Filter the data based on the end date and remove the "id" tag
filtered_data = [{key: value if (key != "endDate" and key != "startDate") else format_date(value) for key, value in obj.items() if key != "id"} for obj in data if is_before_or_equal(obj["endDate"], target_date_str)]

# Write the filtered data to a new file
with open(output_file_path, "w") as f:
    json.dump(filtered_data, f)

print("Filtered data saved to:", output_file_path)



