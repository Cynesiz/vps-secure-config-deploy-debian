#!/bin/bash


function setkern()
{
  step "Setting kernel modules: "
  try modprobe iptable_filter
  try modprobe ip_tables
  try modprobe x_tables 
  try modprobe ip6_tables
  try modprobe iptable_filter
  try modprobe ip6table_filter
  try modprobe xt_tcpudp
  try modprobe xt_owner
  try modprobe xt_conntrack
  try modprobe nf_conntrack
  next
  
  step "Setting configurations via sysctl: "
  try cat >/etc/sysctl.conf<<EOL
fs.file-max = 2097152 
kernel.core_uses_pid = 1
kernel.core_uses_pid = 1 
kernel.kptr_restrict = 2
kernel.msgmax = 65536 
kernel.msgmnb = 65536 
kernel.panic = 10
kernel.panic = 10 
kernel.printk = 4 4 1 7 
kernel.shmall = 4194304 
kernel.shmmax = 4294967296 
kernel.sysrq = 0
kernel.sysrq = 0 
net.core.netdev_max_backlog = 262144 
net.core.optmem_max = 25165824 
net.core.rmem_default = 31457280 
net.core.rmem_max = 67108864 
net.core.somaxconn = 65535 
net.core.wmem_default = 31457280 
net.core.wmem_max = 67108864 
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.all.accept_source_route = 0 
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0 
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1 
net.ipv4.icmp_ignore_bogus_error_responses = 1 
net.ipv4.ip_forward = 0 
net.ipv4.ip_local_port_range = 1024 65000 
net.ipv4.ip_no_pmtu_disc = 1 
net.ipv4.neigh.default.gc_interval = 5 
net.ipv4.neigh.default.gc_stale_time = 120 
net.ipv4.neigh.default.gc_thresh1 = 4096 
net.ipv4.neigh.default.gc_thresh2 = 8192 
net.ipv4.neigh.default.gc_thresh3 = 16384 
net.ipv4.route.flush = 1 
net.ipv4.route.max_size = 8048576 
net.ipv4.tcp_congestion_control = htcp 
net.ipv4.tcp_ecn = 2 
net.ipv4.tcp_fack = 1 
net.ipv4.tcp_fin_timeout = 10 
net.ipv4.tcp_keepalive_intvl = 60 
net.ipv4.tcp_keepalive_probes = 10 
net.ipv4.tcp_keepalive_time = 600 
net.ipv4.tcp_max_orphans = 400000 
net.ipv4.tcp_max_syn_backlog = 16384 
net.ipv4.tcp_max_tw_buckets = 1440000 
net.ipv4.tcp_mem = 65536 131072 262144 
net.ipv4.tcp_no_metrics_save = 1 
net.ipv4.tcp_rfc1337 = 1 
net.ipv4.tcp_rmem = 4096 87380 33554432 
net.ipv4.tcp_sack = 1 
net.ipv4.tcp_slow_start_after_idle = 0 
net.ipv4.tcp_synack_retries = 1 
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_syn_retries = 2 
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_timestamps = 1 
net.ipv4.tcp_tw_recycle = 0 
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_window_scaling = 1 
net.ipv4.tcp_wmem = 4096 87380 33554432 
net.ipv4.udp_mem = 65536 131072 262144 
net.ipv4.udp_rmem_min = 16384 
net.ipv4.udp_wmem_min = 16384 
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.netfilter.nf_conntrack_max = 10000000 
net.netfilter.nf_conntrack_tcp_loose = 0 
net.netfilter.nf_conntrack_tcp_timeout_close = 10 
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10 
net.netfilter.nf_conntrack_tcp_timeout_established = 1800 
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 20 
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 20 
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 10 
vm.dirty_background_ratio = 5 
vm.dirty_ratio = 80 
vm.panic_on_oom = 1
vm.swappiness = 20 
EOL
    try sysctl --system
    next
}


# Source Check 
_LOADED_KERNEL=1
