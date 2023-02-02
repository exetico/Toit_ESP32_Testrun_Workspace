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
  distance_sensor.startContinuous
  while true:
    print "$distance_sensor.horizontal"
        + "(pressed: $distance_sensor.horizontal)"
    sleep --ms=250