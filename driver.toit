// Original C++ Solution: https://github.com/pololu/vl53l0x-arduino
// 
// This is a re-written VL53l0x driver for the To.it language
// 
// Therefore I'll give all credits to the original writer of pololu/vl53l0x-arduino
// For both structure of the code, binary-usage, "how to" and comments in the driver

import binary
import serial


class SequenceStepEnables:
  tcc /int := 0
  msrc /int := 0
  dss /int := 0
  pre_range /int := 0
  final_range /int := 0

class SequenceStepTimeouts:
  pre_range_vcsel_period_pclks /int := 0
  final_range_vcsel_period_pclks /int := 0

  msrc_dss_tcc_mclks /int := 0
  pre_range_mclks /int := 0
  final_range_mclks /int := 0

  msrc_dss_tcc_us /int := 0
  pre_range_us /int := 0
  final_range_us /int := 0


class VL53L0X:
  // Long Range = PR 18, FR 14
  VcselPeriodPreRange /int := 14
  VcselPeriodFinalRange /int := 10

class LIDARDistanceSensorVL53L0X:
  static ENABLE_DEBUG ::= true
  static VERBOSE_DEBUG ::= false

  static I2C_ADDRESS ::= 0x29

  static SYSRANGE_START ::= 0x00

  static SYSTEM_SEQUENCE_CONFIG ::= 0x01
  static SYSTEM_RANGE_CONFIG ::= 0x09
  static SYSTEM_INTERMEASUREMENT_PERIOD ::= 0x04

  static IDENTIFICATION_MODEL_ID ::= 0xC0

  static OSC_CALIBRATE_VAL ::= 0xF8

  static SYSRANGE_START_::= 0x00
  static RESULT_RANGE_STATUS ::= 0x14
  static RESULT_INTERRUPT_STATUS ::= 0x13
  static MSRC_CONFIG_CONTROL ::= 0x60
  static FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT ::= 0x44

  static GLOBAL_CONFIG_SPAD_ENABLES_REF_0            ::= 0xB0
  static GLOBAL_CONFIG_SPAD_ENABLES_REF_1            ::= 0xB1
  static GLOBAL_CONFIG_SPAD_ENABLES_REF_2            ::= 0xB2
  static GLOBAL_CONFIG_SPAD_ENABLES_REF_3            ::= 0xB3
  static GLOBAL_CONFIG_SPAD_ENABLES_REF_4            ::= 0xB4
  static GLOBAL_CONFIG_SPAD_ENABLES_REF_5            ::= 0xB5

  static DYNAMIC_SPAD_REF_EN_START_OFFSET ::= 0x4F
  static DYNAMIC_SPAD_NUM_REQUESTED_REF_SPAD ::= 0x4E
  static GLOBAL_CONFIG_REF_EN_START_SELECT ::= 0xB6

  static SYSTEM_INTERRUPT_CONFIG_GPIO ::= 0x0A
  static GPIO_HV_MUX_ACTIVE_HIGH ::= 0x84

  static SYSTEM_INTERRUPT_CLEAR ::= 0x0B

  static PRE_RANGE_CONFIG_VCSEL_PERIOD ::= 0x50
  static PRE_RANGE_CONFIG_TIMEOUT_MACROP_HI ::= 0x51


  static FINAL_RANGE_CONFIG_VCSEL_PERIOD ::= 0x70
  static FINAL_RANGE_CONFIG_TIMEOUT_MACROP_HI ::= 0x71


  static MSRC_CONFIG_TIMEOUT_MACROP ::= 0x46 


  static io_timeout := 5000 // NOTE_TO_SELF: Should be defined by the user... Right?
  static spad_count := 0
  static spad_type_is_aperture := 0
  static timeout_start_ms /int := 0
  static stop_variable := 0
  static spadinfo := 0
  ref_spad_map := []
  static spads_enabled /int := 0


  registers_/serial.Registers

  constructor device/serial.Device:
    registers_ = device.registers


  checkTimeoutExpired:
    if io_timeout > 0 and ((Time.now.ms_since_epoch - timeout_start_ms ) > io_timeout):
      return true;
    else:
      return false;

  readMulti reg count:
    
    if ENABLE_DEBUG: print "readMulti"
    
    registers_.write_u8 reg I2C_ADDRESS

    // NOTE_TO_SELF: Consider refactor this into a while-loop?
    read1 := registers_.read_u8 reg
    read2 := registers_.read_u8 GLOBAL_CONFIG_SPAD_ENABLES_REF_1
    read3 := registers_.read_u8 GLOBAL_CONFIG_SPAD_ENABLES_REF_2
    read4 := registers_.read_u8 GLOBAL_CONFIG_SPAD_ENABLES_REF_3
    read5 := registers_.read_u8 GLOBAL_CONFIG_SPAD_ENABLES_REF_4
    read6 := registers_.read_u8 GLOBAL_CONFIG_SPAD_ENABLES_REF_5
    
    ref_spad_map = [read1, read2, read3, read4, read5, read6]
    if ENABLE_DEBUG:
      print "readMulti Results"
      print read1
      print read2
      print read3
      print read4
      print read5
      print read6
    // bus->beginTransmission(address);
    // bus->write(reg);
    // last_status = bus->endTransmission();

    // bus->requestFrom(address, count);

    // while (count-- > 0)
    // {
    //   *(dst++) = bus->read();
    // }

  writeMulti reg:
    // NOTE_TO_SELF Consider whileloop, as in the original file
    registers_.write_bytes reg ref_spad_map


  startTimeout:
    if VERBOSE_DEBUG: print "startTimeout"
    timeout_start_ms = Time.now.ms_since_epoch
  
  getSpadInfo:
  
    if ENABLE_DEBUG: print "getSpadInfo"

    tmp := 0

    registers_.write_u8 0x80 0x01
    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x00 0x00

    registers_.write_u8 0xFF 0x06

    readed0x83_No1 := registers_.read_u8 0x83
    print " "
    print "readed0x83_No1"
    print readed0x83_No1
    print " "
    registers_.write_u8 0x83 (readed0x83_No1 | 0x04)
    registers_.write_u8 0xFF 0x07
    registers_.write_u8 0x81 0x01

    registers_.write_u8 0x80 0x01

    registers_.write_u8 0x94 0x6b
    registers_.write_u8 0x83 0x00

    startTimeout

    while (registers_.read_u8 0x83) == 0x00:
      if checkTimeoutExpired:
        return false;

    registers_.write_u8 0x83 0x01

    tmp = registers_.read_u8 0x92
    print [spad_count, tmp, tmp & 0x7f, 0x7f]
    spad_count = tmp & 0x7f;
    print [spad_count, tmp, tmp & 0x7f, 0x7f]
  
    spad_type_is_aperture = (tmp >> 7) & 0x01;

    registers_.write_u8 0x81 0x00
    registers_.write_u8 0xFF 0x06

    readed0x83_No2 := registers_.read_u8 0x83

    if ENABLE_DEBUG:

      print " "
      print "tmp"
      print tmp
      print "spad_count"
      print spad_count
      print "spad_type_is_aperture"
      print spad_type_is_aperture
      print " "

    registers_.write_u8 0x83 readed0x83_No2  & ~0x04
    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x00 0x01

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x80 0x00

    return true
    

  decodeVcselPeriod reg_val:
    // Bit Shift, Left Direction
    // 6 would be 14

    // Explainers below...
    // Number Base: Octal (8)
    // Number: 6
    // Shift Direction: << Left
    // Bits to Shift: 1
    //
    // Decimal: 12
    // Binary: 1100
    // Hexadecimal: c
    // Octal: 14 
    return ((reg_val) + 1) << 1

  calcMacroPeriod vcsel_period_pclks:
    return (((2304 * (vcsel_period_pclks) * 1655) + 500) / 1000)


  timeoutMclksToMicroseconds timeout_period_mclks vcsel_period_pclks:
      macro_period_ns := calcMacroPeriod vcsel_period_pclks;

      return ((timeout_period_mclks * macro_period_ns) + 500) / 1000;


  getVcselPulsePeriod vcselPeriodType:   
    p /VL53L0X? := null
    p = VL53L0X

    VcselPulsePeriodReturn := null

    if vcselPeriodType == p.VcselPeriodPreRange:
      PRE_RANGE_CONFIG := registers_.read_u8 PRE_RANGE_CONFIG_VCSEL_PERIOD
      VcselPulsePeriodReturn = decodeVcselPeriod PRE_RANGE_CONFIG

    else if vcselPeriodType == p.VcselPeriodFinalRange:
      FINAL_RANGE_CONFIG := registers_.read_u8 FINAL_RANGE_CONFIG_VCSEL_PERIOD
      VcselPulsePeriodReturn = decodeVcselPeriod FINAL_RANGE_CONFIG

    else: VcselPulsePeriodReturn = 255; 

    return VcselPulsePeriodReturn

  getSequenceStepEnables enables:
    sequence_config := registers_.read_u8 SYSTEM_SEQUENCE_CONFIG;

    enables.tcc          = (sequence_config >> 4) & 0x1;
    enables.dss          = (sequence_config >> 3) & 0x1;
    enables.msrc         = (sequence_config >> 2) & 0x1;
    enables.pre_range    = (sequence_config >> 6) & 0x1;
    enables.final_range  = (sequence_config >> 7) & 0x1;

    return enables

  getSequenceStepTimeouts enables timeouts:

    p /VL53L0X? := null
    p = VL53L0X


    timeouts.pre_range_vcsel_period_pclks = getVcselPulsePeriod p.VcselPeriodPreRange;

    timeouts.msrc_dss_tcc_mclks = (registers_.read_u8 MSRC_CONFIG_TIMEOUT_MACROP) + 1;

    timeouts.msrc_dss_tcc_us = timeoutMclksToMicroseconds timeouts.msrc_dss_tcc_mclks timeouts.pre_range_vcsel_period_pclks

    PRE_RANGE_CONFIG_TIMEOUT := registers_.read_u16_le PRE_RANGE_CONFIG_TIMEOUT_MACROP_HI
    timeouts.pre_range_mclks = decodeTimeout PRE_RANGE_CONFIG_TIMEOUT

    timeouts.pre_range_us =timeoutMclksToMicroseconds timeouts.pre_range_mclks timeouts.pre_range_vcsel_period_pclks

    timeouts.final_range_vcsel_period_pclks = getVcselPulsePeriod p.VcselPeriodFinalRange

    FINAL_RANGE_CONFIG_TIMEOUT_MACROP := registers_.read_u16_le FINAL_RANGE_CONFIG_TIMEOUT_MACROP_HI
    timeouts.final_range_mclks = decodeTimeout FINAL_RANGE_CONFIG_TIMEOUT_MACROP

    if enables.pre_range:
      timeouts.final_range_mclks -= timeouts.pre_range_mclks
      
    timeouts.final_range_us = timeoutMclksToMicroseconds timeouts.final_range_mclks timeouts.final_range_vcsel_period_pclks

    return timeouts


  // Decode sequence step timeout in MCLKs from register value
  // based on VL53L0X_decode_timeout()
  // Note: the original function returned a uint32_t, but the return value is
  // always stored in a uint16_t.
  decodeTimeout reg_val: 
    // format: "(LSByte * 2^MSByte) + 1"
    return ((reg_val & 0x00FF) <<
          ((reg_val & 0xFF00) >> 8)) + 1;


  // Encode sequence step timeout register value from timeout in MCLKs
  // based on VL53L0X_encode_timeout()
  encodeTimeout timeout_mclks:
    // format: "(LSByte * 2^MSByte) + 1"
    ls_byte := 0; // uint32_t
    ms_byte := 0; // uint16_t

    if timeout_mclks > 0:
      ls_byte = timeout_mclks - 1;

      while ((ls_byte & 0xFFFFFF00) > 0):
        ls_byte >>= 1;
        ms_byte++;
      return (ms_byte << 8) | (ls_byte & 0xFF);

    else: return 0

  setMeasurementTimingBudget budget_us:
    if ENABLE_DEBUG: print "setMeasurementTimingBudget"

    enables := SequenceStepEnables
    timeouts := SequenceStepTimeouts

    startOverhead     := 1910
    endOverhead        := 960
    msrcOverhead       := 660
    tccOverhead        := 590
    dssOverhead        := 690
    preRangeOverhead   := 660
    finalRangeOverhead := 550

    used_budget_us := startOverhead + endOverhead;

    getSequenceStepEnables enables
    getSequenceStepTimeouts enables timeouts

    if enables.tcc:
        used_budget_us += 2 * (timeouts.msrc_dss_tcc_us + tccOverhead);

    if enables.dss:
        used_budget_us += 2 * (timeouts.msrc_dss_tcc_us + dssOverhead);
    else if enables.msrc:
      used_budget_us += (timeouts.msrc_dss_tcc_us + msrcOverhead);
    
    
    if enables.pre_range:
      used_budget_us += (timeouts.pre_range_us + preRangeOverhead);

    if enables.final_range:
      used_budget_us += finalRangeOverhead;

      // NOTE_TO_SELF: Consider to take a bit of time to understand why "used_budget_us += finalRangeOverhead;" is used in set, and the other is used in get...

      // "Note that the final range timeout is determined by the timing
      // budget and the sum of all other timeouts within the sequence.
      // If there is no room for the final range timeout, then an error
      // will be set. Otherwise the remaining time will be applied to
      // the final range."


      if used_budget_us > budget_us:
        // "Requested timeout too big."
        return false;

      final_range_timeout_us := budget_us - used_budget_us;

      // set_sequence_step_timeout() begin
      // (SequenceStepId == VL53L0X_SEQUENCESTEP_FINAL_RANGE)

      // "For the final range timeout, the pre-range timeout
      //  must be added. To do this both final and pre-range
      //  timeouts must be expressed in macro periods MClks
      //  because they have different vcsel periods."

      final_range_timeout_mclks := timeoutMicrosecondsToMclks final_range_timeout_us timeouts.final_range_vcsel_period_pclks

      if enables.pre_range:
        final_range_timeout_mclks += timeouts.pre_range_mclks;

      registers_.write_u16_le FINAL_RANGE_CONFIG_TIMEOUT_MACROP_HI (encodeTimeout final_range_timeout_mclks)

      // set_sequence_step_timeout() end
      measurement_timing_budget_us := budget_us; // store for internal reuse
    return true;


  // Convert sequence step timeout from microseconds to MCLKs with given VCSEL period in PCLKs
  // based on VL53L0X_calc_timeout_mclks()
  timeoutMicrosecondsToMclks timeout_period_us vcsel_period_pclks:
    macro_period_ns := calcMacroPeriod vcsel_period_pclks;

    return (((timeout_period_us * 1000) + (macro_period_ns / 2)) / macro_period_ns);


  performSingleRefCalibration vhv_init_byte:
    registers_.write_u8 SYSRANGE_START (0x01 | vhv_init_byte) // VL53L0X_REG_SYSRANGE_MODE_START_STOP

    startTimeout
    
    while (((registers_.read_u8 RESULT_INTERRUPT_STATUS) & 0x07) == 0):
      if (checkTimeoutExpired):
        return false

    registers_.write_u8 SYSTEM_INTERRUPT_CLEAR 0x01

    registers_.write_u8 SYSRANGE_START 0x00

    return true;


  getMeasurementTimingBudget:
    if ENABLE_DEBUG: print "getMeasurementTimingBudget"

    enables := SequenceStepEnables
    timeouts := SequenceStepTimeouts

    startOverhead     := 1910
    endOverhead        := 960
    msrcOverhead       := 660
    tccOverhead        := 590
    dssOverhead        := 690
    preRangeOverhead   := 660
    finalRangeOverhead := 550

    // "Start and end overhead times always present"
    budget_us := startOverhead + endOverhead;

    print "B1"
    print enables.tcc
    print enables.dss
    print enables.msrc
    print enables.pre_range
    print enables.final_range
    
    enables = getSequenceStepEnables enables

    if ENABLE_DEBUG:
      print "enables values:"
      print [enables.tcc, enables.dss, enables.msrc, enables.pre_range, enables.final_range]


    timeouts = getSequenceStepTimeouts enables timeouts

    if enables.dss:
      budget_us += 2 * (timeouts.msrc_dss_tcc_us + dssOverhead);
    else if enables.msrc:
     budget_us += (timeouts.msrc_dss_tcc_us + msrcOverhead);
    
    
    if enables.pre_range:
     budget_us += (timeouts.pre_range_us + preRangeOverhead);

    if enables.final_range:
     budget_us += (timeouts.final_range_us + finalRangeOverhead);

    // measurement_timing_budget_us = budget_us;

    return budget_us


    
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
    stop_variable = registers_.read_u8 0x91
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


    spadinfo:= getSpadInfo

    if not spadinfo:
      return false;
    else if ENABLE_DEBUG:
      print "Init: spadinfo recieved"



    // The SPAD map (RefGoodSpadMap) is read by VL53L0X_get_info_from_device() in
    // the API, but the same data seems to be more easily readable from
    // GLOBAL_CONFIG_SPAD_ENABLES_REF_0 through _6, so read it from there

    readMulti GLOBAL_CONFIG_SPAD_ENABLES_REF_0 6


    // -- VL53L0X_set_reference_spads() begin (assume NVM values are valid)
    registers_.write_u8 0xFF 0x01
    registers_.write_u8 DYNAMIC_SPAD_REF_EN_START_OFFSET 0x00
    registers_.write_u8 DYNAMIC_SPAD_NUM_REQUESTED_REF_SPAD 0x2C
    registers_.write_u8 0xFF 0x00
    registers_.write_u8 GLOBAL_CONFIG_REF_EN_START_SELECT 0xB4

    // NOTE_TO_SELF: spad_type_is_aperture ... Should that have been defined/set at some point? It looks like it's define at getSpadInfo
    first_spad_to_enable := spad_type_is_aperture ? 12 : 0; // 12 is the first aperture spad
    print "KO"
    print spad_type_is_aperture

    whileMax := 48
    wC := 0

    while wC < whileMax and wC < ref_spad_map.size:
      if wC < first_spad_to_enable or spads_enabled == spad_count:
        // This bit is lower than the first one that should be enabled, or
        // (reference_spad_count) bits have already been enabled, so zero this bit

        //print ref_spad_map
        //print ref_spad_map[wC]/8
        //print ["Test", spads_enabled]
        //print spad_count

        ref_spad_map[wC / 8] = ref_spad_map[wC / 8] ? ref_spad_map[wC / 8] : ~(1 << (wC % 8))
      else if ((ref_spad_map[wC / 8] >> (wC % 8)) and 0x1):
        spads_enabled = spads_enabled +1

      print wC < whileMax
      wC = wC + 1

    writeMulti GLOBAL_CONFIG_SPAD_ENABLES_REF_0

    // -- VL53L0X_set_reference_spads() end

    // -- VL53L0X_load_tuning_settings() begin
    // DefaultTuningSettings from vl53l0x_tuning.h



    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x00 0x00

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x09 0x00
    registers_.write_u8 0x10 0x00
    registers_.write_u8 0x11 0x00

    registers_.write_u8 0x24 0x01
    registers_.write_u8 0x25 0xFF
    registers_.write_u8 0x75 0x00

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x4E 0x2C
    registers_.write_u8 0x48 0x00
    registers_.write_u8 0x30 0x20

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x30 0x09
    registers_.write_u8 0x54 0x00
    registers_.write_u8 0x31 0x04
    registers_.write_u8 0x32 0x03
    registers_.write_u8 0x40 0x83
    registers_.write_u8 0x46 0x25
    registers_.write_u8 0x60 0x00
    registers_.write_u8 0x27 0x00
    registers_.write_u8 0x50 0x06
    registers_.write_u8 0x51 0x00
    registers_.write_u8 0x52 0x96
    registers_.write_u8 0x56 0x08
    registers_.write_u8 0x57 0x30
    registers_.write_u8 0x61 0x00
    registers_.write_u8 0x62 0x00
    registers_.write_u8 0x64 0x00
    registers_.write_u8 0x65 0x00
    registers_.write_u8 0x66 0xA0

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x22 0x32
    registers_.write_u8 0x47 0x14
    registers_.write_u8 0x49 0xFF
    registers_.write_u8 0x4A 0x00

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x7A 0x0A
    registers_.write_u8 0x7B 0x00
    registers_.write_u8 0x78 0x21

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x23 0x34
    registers_.write_u8 0x42 0x00
    registers_.write_u8 0x44 0xFF
    registers_.write_u8 0x45 0x26
    registers_.write_u8 0x46 0x05
    registers_.write_u8 0x40 0x40
    registers_.write_u8 0x0E 0x06
    registers_.write_u8 0x20 0x1A
    registers_.write_u8 0x43 0x40

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x34 0x03
    registers_.write_u8 0x35 0x44

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x31 0x04
    registers_.write_u8 0x4B 0x09
    registers_.write_u8 0x4C 0x05
    registers_.write_u8 0x4D 0x04

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x44 0x00
    registers_.write_u8 0x45 0x20
    registers_.write_u8 0x47 0x08
    registers_.write_u8 0x48 0x28
    registers_.write_u8 0x67 0x00
    registers_.write_u8 0x70 0x04
    registers_.write_u8 0x71 0x01
    registers_.write_u8 0x72 0xFE
    registers_.write_u8 0x76 0x00
    registers_.write_u8 0x77 0x00

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x0D 0x01

    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x80 0x01
    registers_.write_u8 0x01 0xF8

    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x8E 0x01
    registers_.write_u8 0x00 0x01
    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x80 0x00


    // -- VL53L0X_load_tuning_settings() end

    // "Set interrupt config to new sample ready"
    // -- VL53L0X_SetGpioConfig() begin

    registers_.write_u8 SYSTEM_INTERRUPT_CONFIG_GPIO 0x04
    readMuxActiveHighVal := registers_.read_u8 GPIO_HV_MUX_ACTIVE_HIGH
    registers_.write_u8 GPIO_HV_MUX_ACTIVE_HIGH  (readMuxActiveHighVal & ~0x10) // active low
    registers_.write_u8 SYSTEM_INTERRUPT_CLEAR  0x01
    // -- VL53L0X_SetGpioConfig() end


    measurement_timing_budget_us := getMeasurementTimingBudget

    // "Disable MSRC and TCC by default"
    // MSRC = Minimum Signal Rate Check
    // TCC = Target CentreCheck
    // -- VL53L0X_SetSequenceStepEnable() begin
    registers_.write_u8 SYSTEM_SEQUENCE_CONFIG 0xE8

    // -- VL53L0X_SetSequenceStepEnable() end

    // "Recalculate timing budget"
    setMeasurementTimingBudget measurement_timing_budget_us

    // VL53L0X_StaticInit() end

    // VL53L0X_PerformRefCalibration() begin (VL53L0X_perform_ref_calibration())

    // -- VL53L0X_perform_vhv_calibration() begin

    registers_.write_u8 SYSTEM_SEQUENCE_CONFIG 0x01
    if not (performSingleRefCalibration 0x40):
      return false;

    // -- VL53L0X_perform_vhv_calibration() end

    // -- VL53L0X_perform_phase_calibration() begin

    registers_.write_u8 SYSTEM_SEQUENCE_CONFIG 0x02
    if not (performSingleRefCalibration 0x00):
      return false;

    // -- VL53L0X_perform_phase_calibration() end

    // "restore the previous Sequence Config"
    registers_.write_u8 SYSTEM_SEQUENCE_CONFIG 0xE8

    // VL53L0X_PerformRefCalibration() end

    return true;



  startContinuous period_ms:
   // Original: https://github.com/pololu/vl53l0x-arduino/blob/9f3773cb48d4e4e844d689cfc529a06f96d1d264/examples/Continuous/Continuous.ino#L28  

    registers_.write_u8 0x80 0x01
    registers_.write_u8 0xFF 0x01
    registers_.write_u8 0x00 0x00
    registers_.write_u8 0x91 stop_variable
    registers_.write_u8 0x00 0x01
    registers_.write_u8 0xFF 0x00
    registers_.write_u8 0x80 0x00

    if period_ms != 0:
      // NOTE_TO_SELF: This needs to be tested?

      // continuous timed mode

      // VL53L0X_SetInterMeasurementPeriodMilliSeconds() begin

      osc_calibrate_val := registers_.read_u16_le OSC_CALIBRATE_VAL

      if osc_calibrate_val != 0:
        period_ms *= osc_calibrate_val;

      registers_.write_u32_le SYSTEM_INTERMEASUREMENT_PERIOD period_ms

      // VL53L0X_SetInterMeasurementPeriodMilliSeconds() end
      registers_.write_u8 SYSRANGE_START 0x04 // VL53L0X_REG_SYSRANGE_MODE_TIMED

    else:
      // continuous back-to-back mode
      registers_.write_u8 SYSRANGE_START 0x02 // VL53L0X_REG_SYSRANGE_MODE_BACKTOBACK

  readRangeContinuousMillimeters:
    startTimeout

    did_timeout := false

    while (((registers_.read_u8 RESULT_INTERRUPT_STATUS) & 0x07) == 0):
      if (checkTimeoutExpired):
        did_timeout = true
        return 65535;

    // assumptions: Linearity Corrective Gain is 1000 (default);
    // fractional ranging is not enabled
    range := registers_.read_u16_le RESULT_RANGE_STATUS + 10;

    registers_.write_u8 SYSTEM_INTERRUPT_CLEAR 0x01

    return range;


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