//
//  Constants.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 11.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

// #define ORB_BLOCK_MAIN @"orb_block_main"

// accessors.json
#define ORB_VARIABLE_TIMER @"orb_variable_timer"
#define ORB_VARIABLE_TIMER_SET @"orb_variable_timer_set"
#define ORB_VARIABLE_CTRL @"orb_variable_ctrl"
#define ORB_VARIABLE_CTRL_SET @"orb_variable_ctrl_set"
#define ORB_VARIABLE_SPEED @"orb_variable_speed"
#define ORB_VARIABLE_YAW @"orb_variable_yaw"
#define ORB_VARIABLE_PITCH @"orb_variable_pitch"
#define ORB_VARIABLE_ROLL @"orb_variable_roll"
#define ORB_VARIABLE_ACCEL @"orb_variable_accel"
#define ORB_VARIABLE_GYRO @"orb_variable_gyro"
#define ORB_VARIABLE_VBATT @"orb_variable_Vbatt"
#define ORB_VARIABLE_SBATT @"orb_variable_Sbatt"
#define ORB_VARIABLE_CMDROLL @"orb_variable_cmdroll"
#define ORB_VARIABLE_SPDVAL @"orb_variable_spdval"
#define ORB_VARIABLE_HDGVAL @"orb_variable_hdgval"
#define ORB_VARIABLE_CMDRGB @"orb_variable_cmdrgb"
#define ORB_VARIABLE_REDVAL @"orb_variable_redval"
#define ORB_VARIABLE_GRNVAL @"orb_variable_grnval"
#define ORB_VARIABLE_BLUVAL @"orb_variable_bluval"
#define ORB_VARIABLE_ISCONN @"orb_variable_isconn"
#define ORB_VARIABLE_DSHAKE @"orb_variable_dshake"
#define ORB_VARIABLE_ACCELONE @"orb_variable_accelone"
#define ORB_VARIABLE_XPOS @"orb_variable_xpos"
#define ORB_VARIABLE_YPOS @"orb_variable_ypos"
#define ORB_VARIABLE_QZERO @"orb_variable_Qzero"
#define ORB_VARIABLE_QONE @"orb_variable_Qone"
#define ORB_VARIABLE_QTWO @"orb_variable_Qtwo"
#define ORB_VARIABLE_QTHREE @"orb_variable_Qthree"
#define ORB_VARIABLE_ABC @"orb_variable_ABC"
#define ORB_VARIABLE_ABC_SET @"orb_variable_ABC_set"


// branch.json
#define ORB_JUMP @"orb_jump"
#define ORB_GOSUB @"orb_gosub"
#define ORB_ANCHOR @"orb_anchor"
#define ORB_ANCHOR_ID @"orb_anchor_id"
//#define ORB_ANCHOR_VALUE @"orb_anchor_value"
#define ORB_JUMP_INDEXED @"orb_jump_indexed"
#define ORB_GOSUB_INDEXED @"orb_gosub_indexed"
#define ORB_END @"orb_end"
#define ORB_RETURN @"orb_return"
#define ORB_RESET @"orb_reset"
#define ORB_FUNC_SLEEP @"orb_func_sleep"


// function.json
#define ORB_FUNC_DATA @"orb_func_data"
#define ORB_FUNC_READ @"orb_func_read"
#define ORB_FUNC_RSTR @"orb_func_rstr"
#define ORB_FUNC_DELAY @"orb_func_delay"
#define ORB_FUNC_RGB @"orb_func_RGB"
#define ORB_FUNC_LEDC @"orb_func_LEDC"
#define ORB_FUNC_BACKLED @"orb_func_backLED"
#define ORB_FUNC_GOROLL @"orb_func_goroll"
#define ORB_FUNC_HEADING @"orb_func_heading"
#define ORB_FUNC_RAW @"orb_func_raw"
#define ORB_FUNC_LOCATE @"orb_func_locate"
#define ORB_FLAG_BASFLG @"orb_flag_basflg"
#define ORB_FUNC_MATH_RANDOM @"orb_func_math_random" // reseed random

// logic.json
#define LOGIC_COMPARE_MATH @"logic_compare_math"

// math.json
#define ORB_FUNC_MATH_SQRT @"orb_func_math_sqrt"
#define ORB_FUNC_MATH_RND @"orb_func_math_rnd"
#define ORB_FUNC_MATH_ABS @"orb_func_math_abs"
#define MATH_NUMBER @"math_number"
#define ANGLE_BLOCK @"angle_block"
#define MATH_ARITHMETIC @"math_arithmetic"
#define MATH_NUMBER_PROPERTY @"math_number_property"
#define MATH_MODULO @"math_modulo"

// top.json
#define ORB_BLOCK_MAIN @"orb_block_main"
#define ORB_BLOCK_KERNEL @"orb_block_kernel"


// Mutators:
#define ORB_JUMP_INDEXED_MUTATOR @"orb_jump_indexed_mutator"
#define ORB_FUNC_READ_MUTATOR @"orb_func_read_mutator"
#define ORB_FUNC_DATA_MUTATOR @"orb_func_data_mutator"
#define ORB_ANCHOR_SELECTOR @"orb_anchor_selector"
// #define ORB_ANCHOR_DEFINITION @"orb_anchor_definition"
#define ORB_SUPABLOCK_MUTATOR @"orb_supablock_mutator"


#endif /* Constants_h */
