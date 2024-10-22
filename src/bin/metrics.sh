#!/bin/bash

# -------------------------------
# Configuration Variables
# -------------------------------

METRICS_FILE="${METRICS_DIR}/metrics.log"

# Target Annotation
TARGET_ANNOTATION="vault.hashicorp.com/alias-metadata-env"

# Temporary file to store metrics before writing
TEMP_METRICS_FILE=$(mktemp)

# -------------------------------
# Function Definitions
# -------------------------------

# Function to escape label values
escape_label_value() {
    local val="$1"
    val="${val//\\/\\\\}"  # Escape backslash
    val="${val//\"/\\\"}"  # Escape double quote
    val="${val//$'\n'/}"   # Remove newlines
    val="${val//$'\r'/}"   # Remove carriage returns
    echo -n "$val"
}

# Function to write metrics header
write_metrics_header() {
    echo "# HELP vault_sa_alias_metadata_env Indicates the value of vault.hashicorp.com/alias-metadata-env annotation for the Service Account"
    echo "# TYPE vault_sa_alias_metadata_env gauge"
}

# Function to collect and process Service Accounts
collect_metrics() {
    # Fetch all Service Accounts with annotations
    kubectl get serviceaccounts --all-namespaces -o json | jq -c '.items[]' | while read -r sa; do
        sa_name=$(echo "$sa" | jq -r '.metadata.name')
        sa_namespace=$(echo "$sa" | jq -r '.metadata.namespace')
        annotations=$(echo "$sa" | jq -r '.metadata.annotations // empty')

        # Check if the target annotation exists
        annotation_value=$(echo "$sa" | jq -r --arg anno "$TARGET_ANNOTATION" '.metadata.annotations[$anno] // empty')

        # Escape label values
        sa_name_escaped=$(escape_label_value "$sa_name")
        sa_namespace_escaped=$(escape_label_value "$sa_namespace")

        if [[ -n "$annotation_value" ]]; then
            # Annotation is present
            # Escape the annotation value for label
            annotation_value_escaped=$(escape_label_value "$annotation_value")
            echo "vault_sa_alias_metadata_env{service_account=\"${sa_name_escaped}\",namespace=\"${sa_namespace_escaped}\",annotation_value=\"${annotation_value_escaped}\"} 1" >> "$TEMP_METRICS_FILE"
        else
            # Annotation is absent
            echo "vault_sa_alias_metadata_env{service_account=\"${sa_name_escaped}\",namespace=\"${sa_namespace_escaped}\",annotation_value=\"\"} 0" >> "$TEMP_METRICS_FILE"
        fi
    done
}

# -------------------------------
# Main Execution
# -------------------------------

# Write metrics header to temporary file
write_metrics_header > "$TEMP_METRICS_FILE"

# Collect metrics and append to temporary file
collect_metrics

# Move temporary metrics file to the metrics directory atomically
mv "$TEMP_METRICS_FILE" "$METRICS_FILE"

# Optional: Set appropriate permissions
chmod 644 "$METRICS_FILE"
