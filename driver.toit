import binary
import serial

class LIDARDistanceSensorVL53L0X:
  static I2C_ADDRESS ::= 0x29

  static SYSTEM_SEQUENCE_CONFIG ::= 0x01
  static IDENTIFICATION_MODEL_ID ::= 0xC0
  static SYSRANGE_START_::= 0x00
  static RESULT_RANGE_STATUS ::= 0x14
  static RESULT_INTERRUPT_STATUS ::= 0x13
  static MSRC_CONFIG_CONTROL ::= 0x60
  static FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT ::= 0x44

  registers_/serial.Registers

  constructor device/serial.Device:
    registers_ = device.registers

  on:
    print "Test1"

    reg := registers_.read_u8 IDENTIFICATION_MODEL_ID
    print "Test2"
    print reg
    if reg != 0xEE: throw "INVALID_CHIP"

    // Set I2C Standard Mode
    registers_.write_u8 0x80 0x01
    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x00 0x00
    stop_variable := registers_.read_u8 0x91
    registers_.write_u8 0x00 0x01
    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x80 0x00



    // disable SIGNAL_RATE_MSRC (bit 1) and SIGNAL_RATE_PRE_RANGE (bit 4) limit checks
    registers_.write_u8 MSRC_CONFIG_CONTROL  ( registers_.read_u8 MSRC_CONFIG_CONTROL | 0x12)

    // set final range signal rate limit to 0.25 MCPS (million counts per second)
    // setSignalRateLimit(0.25);
    limit_Mcps := 25
    registers_.write_u16_le FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT  ((limit_Mcps/100) * (1 << 7))

    registers_.write_u8 SYSTEM_SEQUENCE_CONFIG 0xFF;

    // Not finished

  off:

  /**
  Returns the horizontal value in the range [-1..1].
  */
  horizontal -> int:
    range := registers_.read_u16_le RESULT_RANGE_STATUS;

    return range

//   /**
//   Returns the vertical value in the range [-1..1].
//   */
//   vertical -> float:
//     return read_position_ REG_VERTICAL_POSITION_

//   /**
//   Returns true if the button is pressed.
//   */
//   pressed -> bool:
//     return (registers_.read_u8 REG_BUTTON_POSITION_) == 0

  read_position_ reg/int -> float:
    value := registers_.read_u16_be reg
    // Move from uint16 range to int16 range.
    value -= binary.INT16_MAX
    // Perform floating-point division to get to [-1..1] range.
    return value.to_float / binary.INT16_MAX