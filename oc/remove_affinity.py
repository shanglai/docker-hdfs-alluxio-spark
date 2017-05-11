#!/usr/bin/env python3

import sys
import os
try:
    import yaml
except ImportError as err:
    raise ImportError("Missing pyyaml. Install with pip install pyyaml.")
import json

with open(sys.argv[1], 'r') as stream:
    try:
        parsed_yaml = yaml.load(stream)
        deploymentConfig_indexes = [k for k,v in enumerate(parsed_yaml["objects"]) if v["kind"] == "DeploymentConfig"]
        for i in deploymentConfig_indexes:
            del parsed_yaml["objects"][i]["spec"]["template"]["metadata"]["annotations"]["scheduler.alpha.kubernetes.io/affinity"]

        print(json.dumps(parsed_yaml))
    except yaml.YAMLError as exc:
        print(exc)