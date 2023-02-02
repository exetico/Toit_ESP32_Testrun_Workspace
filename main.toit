import gpio
import serial.protocols.i2c as i2c

import .driver

main:
  bus := i2c.Bus
    --sda=gpio.Pin 22
    --scl=gpio.Pin 23

  device := bus.device LIDARDistanceSensorVL53L0X.I2C_ADDRESS

  distance_sensor := LIDARDistanceSensorVL53L0X device

  distance_sensor.on

  // NOTE_TO_SELF: Make "period_ms" parameter optional?
  distance_sensor.startContinuous 0 // false, just to provide something
  while true:
    print distance_sensor.readRangeContinuousMillimeters
    // print "$distance_sensor.horizontal"
        // + "(pressed: $distance_sensor.horizontal)"
    sleep --ms=500