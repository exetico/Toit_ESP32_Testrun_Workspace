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

    // Measurement looks more like inches, but still not 1:1...
    
    // I guess it's related to how I handle the "enabled" options and more, so more debugging is still needed.
    // With the sensor placed 2.5cm~ from the target, the readout is 10750~

    // I'm not sure if it's decimal to octal? It could be...

    // Cause 2.5cm ~ 10750 = 25400 octal ... Which is close to the 2.5cm...
    // But 10 cm ~ 28928 = 70400 octal, which doesnt match up

    // So ... Well ... Maybe it's just the configuration, initial calibration or similar ...

    //
    print distance_sensor.readRangeContinuousMillimeters
    // print "$distance_sensor.horizontal"
        // + "(pressed: $distance_sensor.horizontal)"
    sleep --ms=250