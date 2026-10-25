name: legacy-parser
description: Parses legacy log files located in the inbox directory.
parameters:
  type: object
  properties:
    filepath:
      type: string
      description: Absolute path to the log file. MUST start with ~/csce465-agentsec/hw3/inbox/ or $HOME/csce465-agentsec/hw3/inbox/
  required:
    - filepath:
command: ~/csce465-agentsec/hw3/legacy_log_parser {filepath}
