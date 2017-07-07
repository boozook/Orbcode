package fzzr.comp.test;

import haxe.unit.TestCase;

import fzzr.comp.KernelCompiler;


/**
  Created by Alexander "fzzr" Kozlovskij
**/
class BlocksTest extends TestCase
{
	static inline var HEAD = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?><xml xmlns=\"http://www.w3.org/1999/xhtml\">";
	static inline var END = "</xml>";


	override function setup():Void
	{
	}

	function testBlockKernel()
	{
		var src = HEAD + '<block type="orb_block_kernel"><field name="NAME">name</field><statement name="DO0"/></block>' + END;
		var result = KernelCompiler.build(src);
		assertTrue(result != null);
		// assertEquals(1, result.errors.length);
	}

	function testProcedures()
	{
		var src = '
			<block type="orb_block_kernel"> <field name="NAME">name</field>
				<statement name="DO0">
					<block type="procedures_callnoreturn" id="F0581081-EDAC-4D31-B36B-5B1385B2955D">
						<mutation name="do something"/>
					</block>
				</statement>
			</block>';
		var procedure = '
			<block id="14B241F0-5504-412A-BE9A-B897792C3935" type="procedures_defnoreturn">
				<mutation statements="true"/>
				<field name="NAME">do something</field>
				<statement name="STACK">
					<block type="orb_end" id="5988AFC2-1FA5-4602-B5A7-A1BD31B8DAA0"/>
				</statement>
			</block>';

		var result = KernelCompiler.build(HEAD + src + procedure + END);
		assertTrue(result != null);
	}

	function testControlsFor()
	{
		var src = '
			<block type="orb_block_kernel"> <field name="NAME">name</field>
				<statement name="DO0">
					<block type="controls_for" id="882F002E-E42A-43B7-B872-6FDE0F5F1ABD">
						<value name="FROM">
							<shadow type="math_number" id="F94DD15A-C2BC-4E12-B681-165FEEC1AF94">
								<field name="NUM">1</field>
							</shadow>
						</value>
						<field name="VAR">X</field>
						<value name="TO">
							<shadow type="math_number" id="4610F3AB-B780-4EEE-982C-8F7FEE2497ED">
								<field name="NUM">10</field>
							</shadow>
						</value>
						<value name="BY">
							<shadow type="math_number" id="0D62FF27-6DF4-4153-9A63-ACD82D25C0D0">
								<field name="NUM">2</field>
							</shadow>
						</value>
						<statement name="DO">
							<block type="orb_func_locate" id="A6B6DFE5-EF68-436A-A9E9-F39065061190">
								<field name="VALUE">0</field>
								<field name="VALUE">0</field>
								<next>
									<block type="orb_return" id="F0581081-EDAC-4D31-B36B-5B1385B2955D" />
								</next>
							</block>
						</statement>
						<next>
							<block type="orb_end" id="5988AFC2-1FA5-4602-B5A7-A1BD31B8DAA0" />
						</next>
					</block>
				</statement>
			</block>';

		var result = KernelCompiler.build(HEAD + src + END);
		assertTrue(result != null);
	}


	function testControlsForSimple()
	{
		var src = '
			<block type="orb_block_kernel"> <field name="NAME">name</field>
				<statement name="DO0">
					<block type="controls_for_simple" id="D67D712F-7453-4888-95AE-247C5F1A22F1">
						<value name="FROM">
							<shadow type="math_number" id="3646A5C3-0EBF-464D-AFBD-C7C03EC34399">
								<field name="NUM">1</field>
							</shadow>
						</value>
						<field name="VAR">X</field>
						<value name="TO">
							<shadow type="math_number" id="B39B7995-94F5-42A5-9556-F34DC5C92E85">
								<field name="NUM">10</field>
							</shadow>
						</value>
						<statement name="DO">
							<block type="orb_func_LEDC" id="4F71DB7C-5892-43F9-9EC3-F56CAAFCF147">
								<value name="COLOUR">
									<block type="orb_variable_accel" id="404EFC00-BC46-4BE0-9C2A-D9388E84ECE7">
										<field name="ACCEL">X</field>
									</block>
								</value>
								<next>
									<block type="orb_func_LEDC" id="8A83CF92-1535-4758-B1CD-36FFE8BD4B45">
										<value name="COLOUR">
											<block type="math_arithmetic" id="73408A50-3AC3-4E58-954C-FA4430077452">
												<value name="A">
													<block type="angle_block" id="DE33D9D4-E3FF-4771-B17A-A47868178A10">
														<field name="ANGLE">180</field>
													</block>
													<shadow type="math_number" id="DEB71CB7-D946-4F49-874D-7FE87987F169">
														<field name="NUM">1</field>
													</shadow>
												</value>
												<value name="B">
													<block type="orb_func_math_rnd" id="13BAE2D7-34CC-45B5-83FD-4F2D0BB07275">
														<value name="VALUE">
															<block type="orb_variable_Vbatt" id="D248EE21-85A9-470D-92B4-6AA3CA2E702B" />
															<shadow type="math_number" id="62906FD0-5ED2-4A49-B8E8-2832BA34A6B0">
																<field name="NUM">255</field>
															</shadow>
														</value>
													</block>
													<shadow type="math_number" id="31EA4BC3-4C95-4BBF-AED6-E32FBF52433D">
														<field name="NUM">1</field>
													</shadow>
												</value>
												<field name="OP">MULTIPLY</field>
											</block>
										</value>
									</block>
								</next>
							</block>
						</statement>
					</block>
				</statement>
			</block>';

		var result = KernelCompiler.build(HEAD + src + END);
		assertTrue(result != null);
	}

	function testControlsIf_simple()
	{
		var src = '
			<block type="orb_block_kernel"> <field name="NAME">name</field>
				<statement name="DO0">
					<block type="controls_if" id="989C1884-D494-43AD-9AC4-6C0DA2A6F870">
						<mutation elseif="0" else="0" />
						<value name="IF0">
							<block type="logic_negate" id="6F792503-5BE3-4353-AE8D-79A727BA2C49">
								<value name="BOOL">
									<block type="logic_boolean" id="858C1035-21DF-4144-8041-AE40C1648E5F">
										<field name="BOOL">TRUE</field>
									</block>
								</value>
							</block>
						</value>
						<statement name="DO0">
							<block type="orb_reset" id="821E9BAB-06B7-440D-9ABF-46AC9FD0CE68" />
						</statement>
					</block>
				</statement>
			</block>';

		var result = KernelCompiler.build(HEAD + src + END);
		assertTrue(result != null);
	}

	function testControlsIf_multi()
	{
		var src = '
			<block type="orb_block_kernel"> <field name="NAME">name</field>
				<statement name="DO0">
					<block type="controls_if" id="989C1884-D494-43AD-9AC4-6C0DA2A6F870">
						<mutation elseif="0" else="0" />
						<value name="IF0">
							<block type="logic_negate" id="6F792503-5BE3-4353-AE8D-79A727BA2C49">
								<value name="BOOL">
									<block type="logic_boolean" id="858C1035-21DF-4144-8041-AE40C1648E5F">
										<field name="BOOL">TRUE</field>
									</block>
								</value>
							</block>
						</value>
						<statement name="DO0">
							<block type="orb_reset" id="821E9BAB-06B7-440D-9ABF-46AC9FD0CE68">
								<next>
									<block type="orb_reset" id="821E9BAB-06B7-440D-9ABF-46AC9FD0CE68"/>
								</next>
							</block>
						</statement>
					</block>
				</statement>
			</block>';

		var result = KernelCompiler.build(HEAD + src + END);
		assertTrue(result != null);
	}
}
