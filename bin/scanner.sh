#!/bin/bash

echo "Scanning $1"

target_id="$1"
ppath="$(pwd)"
scan_id="$target_id-$(date +%s)"
scan_path="$ppath/scans/$scan_id"
raw_path="$ppath/rawdata/$target_id/"
threads=13
notify="slack"

mkdir -p "$scan_path"
mkdir -p "$raw_path"

cd "$scan_path"
cp "$ppath/scope/$1" "$scan_path/scope.txt"

echo "$ppath"

cat scope.txt | subfinder -json -o subs.json | jq --unbuffered -r '.host' | dnsx -json -o dnsx.json 

find "$scan_path" -type f -name "*.json" -exec "$ppath/bin/import.py" {} "$scan_id" "$target_id" \;

cat subs.json | jq -r '.host' | anew "$raw_path/hosts.txt" > "$raw_path/hosts.txt.new"
notify -bulk -i "$raw_path/hosts.txt.new"  -pc "$ppath/config/notify.yaml" -mf "New Hostnames Found! {{data}}"

cat dnsx.json | jq -r '.host' | anew "$raw_path/resolved.txt"
cat dnsx.json | jq -r '.a?[]?' | anew "$raw_path/ips.txt"
