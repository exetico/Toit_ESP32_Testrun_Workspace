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

    // WORK IN PROGRESS - START

    // NOTE_TO_SELF
    // Measurement looks more like inches, but still not 1:1...
    
    // I guess it's related to how I handle the "enabled" options and more, so more debugging is still needed.
    // With the sensor placed 2.5cm~ from the target, the readout is 10750~

    // I'm not sure if it's decimal to octal? It could be...

    // Cause 2.5cm ~ 10750 = 25400 octal ... Which is close to the 2.5cm...
    // But 10 cm ~ 28928 = 70400 octal, which doesnt match up

    // So ... Well ... Maybe it's just the configuration, initial calibration or similar ...

    // What about inches to cm? ... 1 inch is 2.54 cm...
    // 20 cm position = 56832 readout * 0.39 = 22.16
    // 10cm position = 29000 readout * 0.39 = 11.31
    // 5cm position = 15616 readout * 0.39 = 6.09
    // 2cm position = 8900 readout * 0.39 = 3.471
    // ... So i'm not really sure here... It's pretty close, but still.. It' must be something in the handling of the readout... Or calibration...
    // Or... is it?

    /*
    CM  Readout RO/CM
    22	61440   2792,72727272727
    20	56832   2841,6
    15	43000   2866,66666666667
    10	29000   2900
    7	  20224   2889,14285714286
    5	  15616   3123,2
    2	  8900    4450

    After 23cm~ (65024 RO) it's starting over in the readouts~. So 26cm = 13057 (65024~ + 13057)
    */


    // WORK IN PROGRESS - END

    print "$distance_sensor.readRangeContinuousMillimeters"

    // print "$distance_sensor.horizontal" + "(pressed: $distance_sensor.horizontal)"
    sleep --ms=250