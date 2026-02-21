#!/usr/bin/env bash
# Compatibility wrapper for older calendly CLI command patterns
# Usage: Call this instead of direct calendly CLI
#   events list --event-type "ShapeScale Virtual Demo" --limit 5 --json
#   -> list-events with client-side filtering

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CALENDLY_BIN="$SCRIPT_DIR/../calendly"

# Check if this is a legacy command pattern
if [[ $# -ge 2 && "$1" == "events" && "$2" == "list" ]]; then
    # Legacy: calendly events list --event-type "X" --limit N --json
    event_type=""
    limit="20"
    json_mode=false
    shift 2  # skip "events list"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --event-type)
                event_type="$2"
                shift 2
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            --json)
                json_mode=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Build command
    args=("list-events" "--status" "active" "--count" "$limit")
    if [[ "$json_mode" == true ]]; then
        args+=("-o" "json")
    fi
    
    output=$("$CALENDLY_BIN" "${args[@]}" 2>&1)
    
    # Filter by event type if specified
    if [[ -n "$event_type" && "$json_mode" == true ]]; then
        # Handle both array responses and object responses with collection/data
        output=$(echo "$output" | jq --arg et "$event_type" \
            'if type == "array" then [.[] | select(.name // .event.name // .event_type // "" | contains($et))] 
             elif has("collection") then (.collection // [] | [.[] | select(.name // .event.name // .event_type // "" | contains($et))])
             elif has("data") then (.data // [] | [.[] | select(.name // .event.name // .event_type // "" | contains($et))])
             else . end' 2>/dev/null || echo "$output")
    elif [[ -n "$event_type" ]]; then
        # Text mode - just grep
        echo "$output" | grep -i "$event_type" || true
        exit 0
    fi
    
    echo "$output"
    exit 0
fi

if [[ $# -ge 2 && "$1" == "invitees" && "$2" == "list" ]]; then
    # Legacy: calendly invitees list --event UUID --json
    event_uuid=""
    json_mode=false
    shift 2
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --event)
                event_uuid="$2"
                shift 2
                ;;
            --json)
                json_mode=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -z "$event_uuid" ]]; then
        echo "ERROR: --event UUID required" >&2
        exit 1
    fi
    
    args=("list-event-invitees" "--event-uuid" "$event_uuid")
    if [[ "$json_mode" == true ]]; then
        args+=("-o" "json")
    fi
    
    exec "$CALENDLY_BIN" "${args[@]}"
fi

# Passthrough for normal commands
exec "$CALENDLY_BIN" "$@"
