#!/usr/bin/env python3
"""
>>> import socket
>>> socket.getprotobyname("tcp")
6
>>> socket.getprotobyname("udp")
17
>>> socket.getprotobyname("icmp")
1
>>> socket.getprotobyname("xxx")
Traceback (most recent call last):
  ...
OSError: protocol not found
>>>
"""
import doctest

if doctest.testmod()[0] != 0:
    raise SystemExit(1)

print("OK")
