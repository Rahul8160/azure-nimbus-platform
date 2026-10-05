#!/usr/bin/env bash
# Prints the arguments a resource accepts in the INSTALLED azurerm provider version.
# Usage (from infra/environments/prod):  bash ../../tools/tf-args.sh <resource_type> [filter]
# Example: bash ../../tools/tf-args.sh azurerm_kubernetes_cluster scaling
set -euo pipefail

RESOURCE="${1:?usage: tf-args.sh <resource_type> [filter]}"
FILTER="${2:-}"

terraform providers schema -json > .schema.json

python - "$RESOURCE" "$FILTER" <<'PY'
import json, sys

resource, flt = sys.argv[1], sys.argv[2]
schema = json.load(open(".schema.json"))
block = schema["provider_schemas"]["registry.terraform.io/hashicorp/azurerm"]["resource_schemas"][resource]["block"]

def show(b, indent=""):
    for name, attr in sorted(b.get("attributes", {}).items()):
        if flt in name:
            kind = "required" if attr.get("required") else "optional"
            print(f"{indent}{name}  ({kind})")
    for name, nested in sorted(b.get("block_types", {}).items()):
        print(f"{indent}{name} {{ ... }}")
        show(nested["block"], indent + "    ")

show(block)
PY

rm -f .schema.json