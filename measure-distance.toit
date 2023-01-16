//
// SOURCE: https://github.com/toitlang/toit/blob/master/examples/i2c.toit
//
// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the examples/LICENSE file.

import gpio
import i2c

SDA ::= 22
SCL ::= 23

main:
  print "Creating i2c bus"
  bus := i2c.Bus
      --sda=gpio.Pin SDA
      --scl=gpio.Pin SCL

  print "Scanning"
  found := bus.scan

  print "Found: $found.size devices"
  found.do:
    print "  $(%02x it)"
    print "  $(%02x it)"


// Execute with: `jag run measure-distance.toit` 
// My device is located on: `29`