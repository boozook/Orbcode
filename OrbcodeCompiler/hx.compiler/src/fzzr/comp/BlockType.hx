package fzzr.comp;

@:enum abstract BlockType(String) from String// to String
{
	var KERNEL = "orb_block_kernel";
	var FUNCTION = "TODO: FUNCTION_TYPE";

	// accessors.json
	var ORB_VARIABLE_TIMER = "orb_variable_timer";
	var ORB_VARIABLE_TIMER_SET = "orb_variable_timer_set";
	var ORB_VARIABLE_CTRL = "orb_variable_ctrl";
	var ORB_VARIABLE_CTRL_SET = "orb_variable_ctrl_set";
	var ORB_VARIABLE_SPEED = "orb_variable_speed";
	var ORB_VARIABLE_YAW = "orb_variable_yaw";
	var ORB_VARIABLE_PITCH = "orb_variable_pitch";
	var ORB_VARIABLE_ROLL = "orb_variable_roll";
	var ORB_VARIABLE_ACCEL = "orb_variable_accel";
	var ORB_VARIABLE_GYRO = "orb_variable_gyro";
	var ORB_VARIABLE_VBATT = "orb_variable_Vbatt";
	var ORB_VARIABLE_SBATT = "orb_variable_Sbatt";
	var ORB_VARIABLE_CMDROLL = "orb_variable_cmdroll";
	var ORB_VARIABLE_SPDVAL = "orb_variable_spdval";
	var ORB_VARIABLE_HDGVAL = "orb_variable_hdgval";
	var ORB_VARIABLE_CMDRGB = "orb_variable_cmdrgb";
	var ORB_VARIABLE_REDVAL = "orb_variable_redval";
	var ORB_VARIABLE_GRNVAL = "orb_variable_grnval";
	var ORB_VARIABLE_BLUVAL = "orb_variable_bluval";
	var ORB_VARIABLE_ISCONN = "orb_variable_isconn";
	var ORB_VARIABLE_DSHAKE = "orb_variable_dshake";
	var ORB_VARIABLE_ACCELONE = "orb_variable_accelone";
	var ORB_VARIABLE_XPOS = "orb_variable_xpos";
	var ORB_VARIABLE_YPOS = "orb_variable_ypos";
	var ORB_VARIABLE_QZERO = "orb_variable_Qzero";
	var ORB_VARIABLE_QONE = "orb_variable_Qone";
	var ORB_VARIABLE_QTWO = "orb_variable_Qtwo";
	var ORB_VARIABLE_QTHREE = "orb_variable_Qthree";
	var ORB_VARIABLE_ABC = "orb_variable_ABC";
	var ORB_VARIABLE_ABC_SET = "orb_variable_ABC_set";


	// branch.json
	var ORB_JUMP = "orb_jump";
	var ORB_GOSUB = "orb_gosub";
	var ORB_ANCHOR = "orb_anchor";
	var ORB_ANCHOR_ID = "orb_anchor_id";
	var ORB_ANCHOR_VALUE = "orb_anchor_value";
	var ORB_JUMP_INDEXED = "orb_jump_indexed";
	var ORB_GOSUB_INDEXED = "orb_gosub_indexed";
	var ORB_END = "orb_end";
	var ORB_RETURN = "orb_return";
	var ORB_RESET = "orb_reset";
	var ORB_FUNC_SLEEP = "orb_func_sleep";


	// function.json
	var ORB_FUNC_DATA = "orb_func_data";
	var ORB_FUNC_READ = "orb_func_read";
	var ORB_FUNC_RSTR = "orb_func_rstr";
	var ORB_FUNC_DELAY = "orb_func_delay";
	var ORB_FUNC_DELAY_ALT = "orb_func_delay_alt";
	var ORB_FUNC_RGB = "orb_func_RGB";
	var ORB_FUNC_RGB_ALT = "orb_func_RGB_alt";
	var ORB_FUNC_LEDC = "orb_func_LEDC";
	var ORB_FUNC_BACKLED = "orb_func_backLED";
	var ORB_FUNC_GOROLL_MODE = "orb_func_goroll_mode";
	var ORB_FUNC_GOROLL = "orb_func_goroll";
	var ORB_FUNC_GOROLL_ALT = "orb_func_goroll_alt";
	var ORB_FUNC_HEADING = "orb_func_heading";
	var ORB_FUNC_HEADING_ALT = "orb_func_heading_alt";
	var ORB_FUNC_RAW = "orb_func_raw";
	var ORB_FUNC_RAW_ALT = "orb_func_raw_alt";
	var ORB_FUNC_RAW_MODE = "orb_func_raw_mode";
	var ORB_FUNC_LOCATE = "orb_func_locate";
	var ORB_FUNC_LOCATE_ALT = "orb_func_locate_alt";
	var ORB_FLAG_BASFLG = "orb_flag_basflg";
	var ORB_FUNC_MATH_RANDOM = "orb_func_math_random"; // reseed random

	// logic.json
	var LOGIC_OPERATION = "logic_operation";
	var LOGIC_COMPARE = "logic_compare";
	var LOGIC_COMPARE_MATH = "logic_compare_math";
	var LOGIC_NEGATE = "logic_negate";
	var LOGIC_BOOLEAN = "logic_boolean";

	// math.json
	var ORB_FUNC_MATH_SQRT = "orb_func_math_sqrt";
	var ORB_FUNC_MATH_RND = "orb_func_math_rnd";
	var ORB_FUNC_MATH_ABS = "orb_func_math_abs";
	var MATH_NUMBER = "math_number";
	var ANGLE_BLOCK = "angle_block";
	var MATH_ARITHMETIC = "math_arithmetic";
	var MATH_NUMBER_PROPERTY = "math_number_property";
	var MATH_MODULO = "math_modulo";
	var MATH_CHANGE = "math_change";

	// top.json
	var ORB_BLOCK_MAIN = "orb_block_main";
	var ORB_BLOCK_KERNEL = "orb_block_kernel";


	// builtin:
	var CONTROLS_IF = "controls_if";
	var CONTROLS_FOR = "controls_for";
	var CONTROLS_FOR_SIMPLE = "controls_for_simple";

	// colours:
	var COLOUR_PICKER = "colour_picker";
	var COLOUR_PREDEFINED = "colour_predefined";
	var COLOUR_RGB = "colour_rgb";
	var COLOUR_RANDOM = "colour_random";
	// TODO: impl. COLOUR_PICKER_COMPONENTS_LIST `r,g,b`
	// var COLOUR_PICKER_COMPONENTS_LIST = "colour_picker_components_list";



	// Mutators:
	var ORB_JUMP_INDEXED_MUTATOR = "orb_jump_indexed_mutator";
	var ORB_ANCHOR_SELECTOR = "orb_anchor_selector";
}
