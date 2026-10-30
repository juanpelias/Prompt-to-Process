#include <tunables/global>

/home/ubuntu/csce465-agentsec/hw3/legacy_log_parser {
  #include <abstractions/base>

  /home/ubuntu/csce465-agentsec/hw3/legacy_log_parser mr,
  /lib/x86_64-linux-gnu/libc.so.* mr,
  /lib64/ld-linux-x86-64.so.2 mr,

  /home/ubuntu/csce465-agentsec/hw3/*.bin r,
  /home/ubuntu/csce465-agentsec/hw3/*.log r,

  /home/ubuntu/csce465-agentsec/hw3/markers/ rw,
  /home/ubuntu/csce465-agentsec/hw3/markers/*.txt rw,

  audit deny /opt/agentsec/decoy.txt rwklx,
  audit deny /opt/agentsec/** rwklx,

  audit deny /bin/** x,
  audit deny /usr/bin/** x,
  audit deny /sbin/** x,
  audit deny /usr/sbin/** x,
}
