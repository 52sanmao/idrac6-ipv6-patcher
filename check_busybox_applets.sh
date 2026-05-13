(printf 'CMCCAdmin\r'; sleep 1; printf 'kPwTG@4F@C1\r'; sleep 2; printf 'busybox 2>&1 | grep -E "httpd|tcpsvd|telnetd|ftpd" | head -5\r'; printf 'exit\r'; sleep 2) | telnet 192.168.0.1 23
