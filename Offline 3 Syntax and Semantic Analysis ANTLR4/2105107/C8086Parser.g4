parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include "C8086Lexer.h"
	#include "str_list.cpp"
	#include "cpp_files/compound_statement_list.cpp"
	#include "cpp_files/program_unit.cpp"
	#include "cpp_files/symbol_table.h"
	#include "cpp_files/param_list.cpp"
	

	
    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;

    extern int syntaxErrorCount;
}

@parser::members {
	// int flag_func=0; // 0: not in function, 1: in function
	int func_scope_on = 0; // 0: not in function, 1: in function
	SymbolTable mySymbolTable;

    void writeIntoparserLogFile(const std::string message) {
        if (!parserLogFile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return;
        }

        parserLogFile << message << std::endl;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }
}


start : program

	{
		
		writeIntoparserLogFile("\n\n");
		writeIntoparserLogFile(
			"Line " + 
			std::to_string($program.var_list.getLineNumber()) + 
			": start : program\n"
		);
		mySymbolTable.printAllScopes(parserLogFile);
		writeIntoparserLogFile("Total lines: " + std::to_string($program.var_list.getLineNumber()) );
       writeIntoparserLogFile("Total errors: " + std::to_string(syntaxErrorCount) + "\n");
	}
	;

program returns[program_unit_list var_list]: p=program u=unit 
{
	
	$var_list.set_variables($p.var_list.get_variables());
	$var_list.add($u.var_list.get_list_as_string());
	$var_list.setLineNumber($u.var_list.getLineNumber());
	writeIntoparserLogFile("\nLine " + std::to_string($u.var_list.getLineNumber()) + ": program : program unit\n");
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
	| unit
	{
		$var_list.add($unit.var_list.get_list_as_string());
		$var_list.setLineNumber($unit.var_list.getLineNumber());
		writeIntoparserLogFile("\nLine " + std::to_string($unit.var_list.getLineNumber()) + ": program : unit\n");
		writeIntoparserLogFile($unit.var_list.get_list_as_string() + "\n\n");
	}
	;
	
unit returns [str_list var_list]: var_declaration 
{
	writeIntoparserLogFile(
		std::string("Line ") + 
		std::to_string($var_declaration.var_list.getLineNumber())+
		std::string(": unit : var_declaration\n")
	);
	$var_list.setLineNumber($var_declaration.var_list.getLineNumber());
	$var_list.set_variables($var_declaration.var_list.get_variables());
	writeIntoparserLogFile($var_declaration.var_list.get_list_as_string()+"\n");
}
     | func_declaration
	 {
		 writeIntoparserLogFile(
			 std::string("Line ") + 
			 std::to_string($func_declaration.start->getLine())+
			 std::string(": unit : func_declaration\n")
		 );
		 $var_list.setLineNumber($func_declaration.start->getLine());
		 $var_list.set_variables($func_declaration.var_list.get_variables());
		 writeIntoparserLogFile($func_declaration.var_list.get_list_as_string() + "\n");
		//  $var_list.set_variables
	
	 }
     | func_definition
	 {
		 writeIntoparserLogFile(
			 std::string("Line ") + 
			 std::to_string($func_definition.var_list.getLineNumber())+
			 std::string(": unit : func_definition\n")
		 );
		 $var_list.setLineNumber($func_definition.var_list.getLineNumber());
		 $var_list.set_variables($func_definition.var_list.get_variables());
		 writeIntoparserLogFile($func_definition.var_list.get_list_as_string() + "\n");
	 }

	 ;

func_declaration returns[str_list var_list]: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
{
	$var_list.setLineNumber($ID->getLine());
	writeIntoparserLogFile(
		std::string("Line ") + 
		std::to_string($ID->getLine())+
		std::string(": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n")
	);
	writeIntoparserLogFile($type_specifier.var_list.get_list_as_string() + " " + $ID->getText() + $LPAREN->getText() + $parameter_list.var_list.get_list_as_string() + $RPAREN->getText() + $SEMICOLON->getText() + "\n");
	$var_list.add($type_specifier.var_list.get_list_as_string() + " " + $ID->getText() + $LPAREN->getText() + $parameter_list.var_list.get_list_as_string() + $RPAREN->getText() + $SEMICOLON->getText());
	
	

}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$var_list.setLineNumber($ID->getLine());
			writeIntoparserLogFile(
				std::string("Line ") + 
				std::to_string($ID->getLine())+
				std::string(": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n")
			);
			$var_list.add($type_specifier.var_list.get_list_as_string() + " " + $ID->getText() +$LPAREN->getText()+$RPAREN->getText()+$SEMICOLON->getText() );
			writeIntoparserLogFile($type_specifier.var_list.get_list_as_string() + " " + $ID->getText() +$LPAREN->getText()+$RPAREN->getText()+$SEMICOLON->getText() + "\n\n");
			
		}
		;
		 
func_definition returns[str_list var_list]: ts=type_specifier ID{
		mySymbolTable.insert($ID->getText(), "ID", "", cout);
	} LPAREN pl=parameter_list{
		mySymbolTable.enterScope();
		func_scope_on = 1; // Indicate that we are in a function scope
		vector<pair<string,string>> paramVars = $pl.var_list.get_variables();
		for (size_t i = 0; i < paramVars.size(); i++) {
			mySymbolTable.insert(paramVars[i].second, "ID", "", cout);
		}
	} RPAREN cs=compound_statement
{

	writeIntoparserLogFile("\n");
	// mySymbolTable.printAllScopes(parserLogFile);



	writeIntoparserLogFile(
		std::string("Line ") + 
		std::to_string($cs.var_list.getLineNumber())+
		std::string(": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n")
	);

	writeIntoparserLogFile(
		$ts.var_list.get_list_as_string() + " " + 
		$ID->getText() + $LPAREN->getText() +
		$pl.var_list.get_list_as_string()  + $RPAREN->getText() +
		$cs.var_list.get_list_as_string() + "\n"
	);

	$var_list.setLineNumber($cs.var_list.getLineNumber());
	$var_list.add(
		$ts.var_list.get_list_as_string() + " " + 
		$ID->getText() + $LPAREN->getText() +
		$pl.var_list.get_list_as_string()  + $RPAREN->getText() + 
		$cs.var_list.get_list_as_string()
	);

}
		| ts=type_specifier ID{
			mySymbolTable.insert($ID->getText(), "ID", "", cout);
		} LPAREN RPAREN {
			mySymbolTable.enterScope();
			func_scope_on = 1; // Indicate that we are in a function scope
		} cs=compound_statement {
						
	
			$var_list.setLineNumber($cs.var_list.getLineNumber());
			writeIntoparserLogFile(
				std::string("Line ") + 
				std::to_string($cs.var_list.getLineNumber())+
				std::string(": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n")
			);
			$var_list.add(
				$ts.var_list.get_list_as_string() 
				+ $ID->getText() + $LPAREN->getText() 
				+ $RPAREN->getText() + 
				$cs.var_list.get_list_as_string());
			writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		}
 		;				


parameter_list returns [paramList var_list] : pm=parameter_list COMMA type_specifier ID
{
	$var_list.setLineNumber($ID->getLine());

	writeIntoparserLogFile(
		std::string("Line ") + 
		std::to_string($ID->getLine())+
		std::string(": parameter_list : parameter_list COMMA type_specifier ID\n")
	);

	writeIntoparserLogFile($pm.var_list.get_list_as_string() + "," + $type_specifier.var_list.get_list_as_string() + " " + $ID->getText()+"\n");
	
	
	$var_list.set_variables($pm.var_list.get_variables());
	$var_list.add($type_specifier.var_list.get_list_as_string(),$ID->getText());
	// writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		{
			writeIntoparserLogFile(
				std::string("Line ") + 
				std::to_string($ID->getLine())+
				std::string(": parameter_list : type_specifier ID\n")
			);
			$var_list.setLineNumber($ID->getLine());
			$var_list.add($type_specifier.var_list.get_list_as_string(),$ID->getText());
			// $var_list.add($type_specifier.var_list.get_list_as_string() + " " + $ID->getText());
			writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
			
		}
		| type_specifier
 		;

 		
compound_statement returns[comp_statement_list var_list]: LCURL{
	if(func_scope_on == 0) {
		mySymbolTable.enterScope();
	}
	else func_scope_on=0;
} statements RCURL{
	writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL statements RCURL\n");
	
	$var_list.setLineNumber($RCURL->getLine());

	$var_list.add($LCURL->getText());
	for (const auto& item : $statements.var_list.get_variables()) {
		$var_list.add(item);
	}
	$var_list.add($RCURL->getText());

	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
	
	mySymbolTable.exitScope(parserLogFile);
	

}

 		    | LCURL RCURL
 		    ;
 		    
var_declaration  returns [str_list var_list]
    : t=type_specifier dl=declaration_list sm=SEMICOLON {

        writeIntoparserLogFile(std::string("Line ")+ std::to_string($sm->getLine())+
            std::string(": var_declaration:  type_specifier declaration_list SEMICOLON\n")
        );

		
		writeIntoparserLogFile($t.var_list.get_list_as_string() + " "+ $dl.var_list.get_list_as_string()+$sm->getText() + "\n");

		$var_list.set_variables($t.var_list.get_variables());
		$var_list.add($dl.var_list.get_list_as_string());
		$var_list.add($sm->getText());
		$var_list.setLineNumber($sm->getLine());

      }

    | t=type_specifier de=declaration_list_err sm=SEMICOLON {
        writeIntoErrorFile(
            std::string("Line ") + std::to_string($sm->getLine()) +
            " with error name: " + $de.error_name +
            " - Syntax error at declaration list of variable declaration"
        );
        syntaxErrorCount++;
      }
    ;

declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };

 		 
type_specifier returns [str_list var_list]	
    : INT {
       	$var_list.add($INT->getText());
		$var_list.setLineNumber($INT->getLine());
		writeIntoparserLogFile("Line " + std::to_string($INT->getLine())+": type_specifier : INT\n");
		writeIntoparserLogFile("int\n");
    }
    | FLOAT {
		$var_list.add($FLOAT->getText());
		$var_list.setLineNumber($FLOAT->getLine());
        writeIntoparserLogFile("Line " + std::to_string($FLOAT->getLine())+": type_specifier : FLOAT\n");
		writeIntoparserLogFile("float\n");
    }
    | VOID {
		$var_list.add($VOID->getText());
		$var_list.setLineNumber($VOID->getLine());
        writeIntoparserLogFile("Line " + std::to_string($VOID->getLine())+": type_specifier : VOID\n");
		writeIntoparserLogFile("void\n");
    }
    ;

// declaration_list : declaration_list COMMA ID
// 				{
// 					writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list: " + $ID->getText() );
// 					// $str_list.add($ID->getText());
// 				}
//                 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
//                 | ID
// 				| ID LTHIRD CONST_INT RTHIRD
// 	;

// writeIntoparserLogFile("list before: " + $dl.var_list.get_list_as_string() + " size: " + $dl.var_list.size());

declaration_list returns [str_list var_list] : dl=declaration_list {} COMMA ID 
			{
				bool temp_bool=mySymbolTable.insert($ID->getText(), "ID","",std::cout);
				// cout<<"alvee"<<endl;
				cout<<"temp_bool: " << temp_bool <<" id: " << $ID->getText() << endl;
				if(!temp_bool) {
					writeIntoErrorFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					writeIntoparserLogFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					syntaxErrorCount++;
				}
				

					$var_list.set_variables($dl.var_list.get_variables());
					$var_list.add($COMMA->getText());
					$var_list.add($ID->getText());
					// $var_list.add($COMMA->getText());
					writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID\n");
					// writeIntoparserLogFile($ID->getText() );
					// writeIntoparserLogFile("Added variable: " + $ID->getText() + " to declaration list at line " + std::to_string($ID->getLine()));
					writeIntoparserLogFile($var_list.get_list_as_string()+ "\n");
				

				
			}
 		  | dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		  {		cout<<"i am here"<<endl;
				bool temp_bool=mySymbolTable.insert($ID->getText(), "ID","",std::cout);
				cout<<"temp_bool: " << temp_bool <<" id: " << $ID->getText() << endl;
				
				if(!temp_bool) {
					writeIntoErrorFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					writeIntoparserLogFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					syntaxErrorCount++;
				}
			

				$var_list.set_variables($dl.var_list.get_variables());
				$var_list.add($COMMA->getText());
				$var_list.add($ID->getText() + $LTHIRD->getText() + $CONST_INT->getText() + $RTHIRD->getText());
				writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
				writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
				
		  }
 		  | ID 
		  	{	bool temp_bool=mySymbolTable.insert($ID->getText(), "ID","",std::cout);
				if(!temp_bool) {
					writeIntoErrorFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					writeIntoparserLogFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					syntaxErrorCount++;
				}
				
				writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID\n");
				writeIntoparserLogFile($ID->getText() + "\n");
				$var_list.add($ID->getText());
				
				
			}
			
 		  | ID LTHIRD CONST_INT RTHIRD
		  {		cout<<"alvee"<<endl;
				bool temp_bool=mySymbolTable.insert($ID->getText(), "ID","",std::cout);
				cout<<"kash"<<endl;
				if(!temp_bool) {
					writeIntoErrorFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					writeIntoparserLogFile("Error at line "+std::to_string($ID->getLine()) + 
						": Multiple declaration of " + $ID->getText() +"\n");
					syntaxErrorCount++;
				}
				
					writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
					$var_list.add($ID->getText() + $LTHIRD->getText() + $CONST_INT->getText() + $RTHIRD->getText());
					writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
				
		  }
 		  ;
 		  
statements returns[str_list var_list]: statement
{
	writeIntoparserLogFile("Line " + std::to_string($statement.var_list.getLineNumber()) + ": statements : statement\n");
	writeIntoparserLogFile($statement.var_list.get_list_as_string() + "\n\n");
	
	$var_list.setLineNumber($statement.var_list.getLineNumber());
	$var_list.add($statement.var_list.get_list_as_string());
}
	   | ss=statements statement
	   {
		$var_list.setLineNumber($statement.var_list.getLineNumber());
		$var_list.set_variables($ss.var_list.get_variables());
		$var_list.add($statement.var_list.get_list_as_string());
		writeIntoparserLogFile("Line " + std::to_string($statement.var_list.getLineNumber()) + ": statements : statements statement\n");
		
		
		// writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		statements_str_for_print newprint;
		newprint.set_variables($var_list.get_variables());
		writeIntoparserLogFile(newprint.get_list_as_string() + "\n");

	   }
	   ;
	   
statement returns [str_list var_list]: var_declaration
{
	writeIntoparserLogFile("Line " + std::to_string($var_declaration.var_list.getLineNumber()) + ": statement : var_declaration\n");
	writeIntoparserLogFile($var_declaration.var_list.get_list_as_string() + "\n");
	$var_list.set_variables($var_declaration.var_list.get_variables());
	$var_list.setLineNumber($var_declaration.var_list.getLineNumber());
}
	  | expression_statement
	  {
		writeIntoparserLogFile("Line " + std::to_string($expression_statement.var_list.getLineNumber()) + ": statement : expression_statement\n");
		writeIntoparserLogFile($expression_statement.var_list.get_list_as_string() + "\n");
		$var_list.setLineNumber($expression_statement.var_list.getLineNumber());
		$var_list.add($expression_statement.var_list.get_list_as_string());
	  }
	  | compound_statement
	  {
		// $var_list.set_variables($compound_statement.var_list.get_variables());
		$var_list.setLineNumber($compound_statement.var_list.getLineNumber());
		$var_list.add($compound_statement.var_list.get_list_as_string());
		writeIntoparserLogFile("Line " + std::to_string($compound_statement.var_list.getLineNumber()) + ": statement : compound_statement\n");
		writeIntoparserLogFile($compound_statement.var_list.get_list_as_string() + "\n");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement

	  {

	  }
	  | IF LPAREN expression RPAREN statement
	  {
		$var_list.setLineNumber($statement.var_list.getLineNumber());
		writeIntoparserLogFile("Line " + std::to_string($IF->getLine()) + ": statement : IF LPAREN expression RPAREN statement\n");
		$var_list.add($IF->getText() + " "+$LPAREN->getText() + $expression.var_list.get_list_as_string() 
		+ $RPAREN->getText()+
		$statement.var_list.get_list_as_string());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n\n");
	  }
	  | IF LPAREN expression RPAREN s1=statement ELSE s2=statement
	  {
		$var_list.setLineNumber($s2.var_list.getLineNumber());
		writeIntoparserLogFile("Line " + std::to_string($s2.var_list.getLineNumber()) + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n");
		$var_list.add($IF->getText() + " " + $LPAREN->getText() + $expression.var_list.get_list_as_string() 
		+ $RPAREN->getText() + $s1.var_list.get_list_as_string() + "\n"+$ELSE->getText() + $s2.var_list.get_list_as_string());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n\n");

	  }
	  | WHILE LPAREN expression RPAREN statement
	  {

	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		$var_list.setLineNumber($SEMICOLON->getLine());
		writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
	  }
	  | RETURN expression SEMICOLON
	  {
		$var_list.setLineNumber($RETURN->getLine());
		writeIntoparserLogFile("Line " + std::to_string($RETURN->getLine()) + ": statement : RETURN expression SEMICOLON\n");
		$var_list.add($RETURN->getText() + " " + $expression.var_list.get_list_as_string() + $SEMICOLON->getText());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n\n");
	  }
	  ;
	  
expression_statement returns[ str_list var_list]	: SEMICOLON	
{
	$var_list.setLineNumber($SEMICOLON->getLine());
	$var_list.add($SEMICOLON->getText());
	writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": expression_statement : SEMICOLON\n");
	writeIntoparserLogFile($SEMICOLON->getText() + "\n");
}		
			| expression SEMICOLON
			{
				writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": expression_statement : expression SEMICOLON\n");
				writeIntoparserLogFile($expression.var_list.get_list_as_string() + $SEMICOLON->getText() + "\n");
				$var_list.add($expression.var_list.get_list_as_string() + $SEMICOLON->getText());
				$var_list.setLineNumber($SEMICOLON->getLine());
			} 
			;
	  
variable returns [variable_type_list var_list] : ID 
	{	
		bool isDeclared = mySymbolTable.find($ID->getText());
		if(!isDeclared){
			writeIntoErrorFile("Error at line " + std::to_string($ID->getLine()) + ": Undeclared variable '" + $ID->getText() + "\n");
			syntaxErrorCount++;
			writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine()) + ": Undeclared variable '" + $ID->getText() + "\n");
		}
		
		$var_list.variable_id_name= $ID->getText();
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": variable : ID\n");
		writeIntoparserLogFile($ID->getText() + "\n");
		$var_list.add($ID->getText());
		$var_list.setLineNumber($ID->getLine());
	}		
	 | ID LTHIRD expression RTHIRD 
	 {
		$var_list.variable_id_name= $ID->getText();
		//check the expression is int or not
		string type_name= $expression.var_list.get_factor_const_type();
		if(type_name != "CONST_INT"){
			writeIntoErrorFile("Error at line " + std::to_string($ID->getLine()) + ": Expression inside third brackets not an integer\n");
			writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine()) + ": Expression inside third brackets not an integer\n");
			syntaxErrorCount++;
		}
		
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": variable : ID LTHIRD expression RTHIRD\n");
		$var_list.add($ID->getText() + $LTHIRD->getText() + $expression.var_list.get_list_as_string() + $RTHIRD->getText());	
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		$var_list.setLineNumber($ID->getLine());
	
		
	 }
	 ;
	 
 expression returns [str_list var_list] : logic_expression
 {
	$var_list.set_factor_const_type($logic_expression.var_list.get_factor_const_type());
	$var_list.set_variables($logic_expression.var_list.get_variables());
	$var_list.setLineNumber($logic_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($logic_expression.var_list.getLineNumber()) + ": expression : logic expression\n");
	writeIntoparserLogFile($logic_expression.var_list.get_list_as_string() + "\n");
 }	
	| variable ASSIGNOP logic_expression 
	{
		writeIntoparserLogFile("Line " + std::to_string($variable.var_list.getLineNumber()) + ": expression : variable ASSIGNOP logic_expression\n");
		
		
		writeIntoparserLogFile($variable.var_list.get_list_as_string() + 
		$ASSIGNOP->getText()  + $logic_expression.var_list.get_list_as_string() 
		+ "\n");

		
		// cout<<"variable_id_type: " << $variable.var_list.variable_id_type << endl;
		string tn= $logic_expression.var_list.get_factor_const_type();
		
		$var_list.add($variable.var_list.get_list_as_string() + $ASSIGNOP->getText() + $logic_expression.var_list.get_list_as_string());
		$var_list.setLineNumber($variable.var_list.getLineNumber());
	}	
	;

logic_expression returns [str_list var_list] : rel_expression
{
	$var_list.set_factor_const_type($rel_expression.var_list.get_factor_const_type());
	$var_list.set_variables($rel_expression.var_list.get_variables());
	$var_list.setLineNumber($rel_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($rel_expression.var_list.getLineNumber()) + ": logic_expression : rel_expression\n");
	writeIntoparserLogFile($rel_expression.var_list.get_list_as_string() + "\n");
}
		 | r1=rel_expression LOGICOP r2=rel_expression
		 {
			// $var_list.set_variables($r1.var_list.get_variables());
			$var_list.setLineNumber($r1.var_list.getLineNumber());
			$var_list.add($r1.var_list.get_list_as_string() + $LOGICOP->getText() + $r2.var_list.get_list_as_string());
			writeIntoparserLogFile("Line " + std::to_string($r1.var_list.getLineNumber()) + ": logic_expression : rel_expression LOGICOP rel_expression\n");
			writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		 }
		 ;

rel_expression returns [str_list var_list]:
		| s1=simple_expression RELOP s2=simple_expression
		{
			$var_list.add($s1.var_list.get_list_as_string() + $RELOP->getText() + $s2.var_list.get_list_as_string());
			$var_list.setLineNumber($s1.var_list.getLineNumber());
			writeIntoparserLogFile("Line " + std::to_string($s1.var_list.getLineNumber()) + ": rel_expression : simple_expression RELOP simple_expression\n");
			writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		}
		| simple_expression
		{
			$var_list.set_factor_const_type($simple_expression.var_list.get_factor_const_type());
			$var_list.set_variables($simple_expression.var_list.get_variables());
			$var_list.setLineNumber($simple_expression.var_list.getLineNumber());
			writeIntoparserLogFile("Line " + std::to_string($simple_expression.var_list.getLineNumber()) + ": rel_expression : simple_expression\n");
			writeIntoparserLogFile($simple_expression.var_list.get_list_as_string() + "\n");
		}
		| re=rel_expression RELOP simple_expression 
		{
			$var_list.add($re.var_list.get_list_as_string() + $RELOP->getText() + $simple_expression.var_list.get_list_as_string());
			$var_list.setLineNumber($re.var_list.getLineNumber());
			writeIntoparserLogFile("Line " + std::to_string($re.var_list.getLineNumber()) + ": rel_expression : rel_expression RELOP simple_expression\n");
			writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		}
		| 
		;
				
simple_expression returns [str_list var_list]: term 
{
	$var_list.set_factor_const_type($term.var_list.get_factor_const_type());
	$var_list.set_variables($term.var_list.get_variables());
	$var_list.setLineNumber($term.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($term.var_list.getLineNumber()) + ": simple_expression : term\n");
	writeIntoparserLogFile($term.var_list.get_list_as_string() + "\n");
}
		  | se=simple_expression ADDOP term 
		  {
			//   $var_list.set_variables($se.var_list.get_variables());
			  $var_list.setLineNumber($se.var_list.getLineNumber());
			  writeIntoparserLogFile("Line " + std::to_string($se.var_list.getLineNumber()) + ": simple_expression : simple_expression ADDOP term\n");
			  writeIntoparserLogFile($se.var_list.get_list_as_string() + $ADDOP->getText() + $term.var_list.get_list_as_string() + "\n");
			  $var_list.add($se.var_list.get_list_as_string() + $ADDOP->getText() + $term.var_list.get_list_as_string());
		  }
		  ;
					
term returns[str_list var_list]:	unary_expression
{
	$var_list.set_factor_const_type($unary_expression.var_list.get_factor_const_type());
	$var_list.set_variables($unary_expression.var_list.get_variables());
	$var_list.setLineNumber($unary_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($unary_expression.var_list.getLineNumber()) + ": term : unary_expression\n");
	writeIntoparserLogFile($unary_expression.var_list.get_list_as_string() + "\n");
}
     |  t=term MULOP unary_expression
{
	writeIntoparserLogFile("Line " + std::to_string($t.var_list.getLineNumber()) + ": term : term MULOP unary_expression\n");
	// writeIntoparserLogFile($t.var_list.get_list_as_string() + $MULOP->getText() + $unary_expression.var_list.get_list_as_string() + "\n");
	// $var_list.set_variables($t.var_list.get_variables());
	
	if($MULOP->getText()=="%"){
		if($unary_expression.var_list.get_factor_const_type() != "CONST_INT"){
			writeIntoErrorFile("Error at line " + std::to_string($unary_expression.var_list.getLineNumber()) + ": Non-Integer opearand on modulus operator \n");
			writeIntoparserLogFile("Error at line " + std::to_string($unary_expression.var_list.getLineNumber()) + ": Non-Integer opearand on modulus operator \n");
			syntaxErrorCount++;
		}
	}
	
	$var_list.setLineNumber($t.var_list.getLineNumber());
	$var_list.add($t.var_list.get_list_as_string() + $MULOP->getText() + $unary_expression.var_list.get_list_as_string());
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
     ;

unary_expression returns [str_list var_list]: ADDOP unary_expression 
{
	
	$var_list.setLineNumber($unary_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($unary_expression.var_list.getLineNumber()) + ": unary_expression : ADDOP unary_expression\n");
	
	$var_list.add($ADDOP->getText() + $unary_expression.var_list.get_list_as_string());
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
} 
		 | NOT unary_expression 
{
	$var_list.setLineNumber($unary_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($unary_expression.var_list.getLineNumber()) + ": unary_expression : NOT unary expression\n");
	$var_list.add($NOT->getText() + $unary_expression.var_list.get_list_as_string());
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
		 | factor 
		 {
			$var_list.set_factor_const_type($factor.var_list.get_factor_const_type());
			writeIntoparserLogFile("Line " + std::to_string($factor.var_list.getLineNumber()) + ": unary_expression : factor\n");
			writeIntoparserLogFile($factor.var_list.get_list_as_string() + "\n");
			$var_list.set_variables($factor.var_list.get_variables());
			$var_list.setLineNumber($factor.var_list.getLineNumber());
		 }
		 ;

factor returns [str_list var_list]: variable 
{
	writeIntoparserLogFile("Line " + std::to_string($variable.var_list.getLineNumber()) + ": factor : variable\n");
	writeIntoparserLogFile($variable.var_list.get_list_as_string() + "\n");
	$var_list.set_variables($variable.var_list.get_variables());
	$var_list.setLineNumber($variable.var_list.getLineNumber());
}
	| ID LPAREN argument_list RPAREN
	{
		$var_list.add($ID->getText()+$LPAREN->getText() + $argument_list.var_list.get_list_as_string() + $RPAREN->getText());
		$var_list.setLineNumber($argument_list.var_list.getLineNumber());
		writeIntoparserLogFile("Line " + std::to_string($argument_list.var_list.getLineNumber()) + ": factor : ID LPAREN argument_list RPAREN\n");
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
	}
	| ID LPAREN RPAREN
	| ID LPAREN argument_list RPAREN
	| LPAREN expression RPAREN
	{
		writeIntoparserLogFile("Line " + std::to_string($expression.var_list.getLineNumber()) + ": factor : LPAREN expression RPAREN\n");
		// writeIntoparserLogFile($expression.var_list.get_list_as_string() + "\n");
		// $var_list.set_variables($expression.var_list.get_variables());
		$var_list.add($LPAREN->getText() + $expression.var_list.get_list_as_string() + $RPAREN->getText());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		$var_list.setLineNumber($expression.var_list.getLineNumber());
	}
	| CONST_INT 
	{
		$var_list.set_factor_const_type("CONST_INT");
		writeIntoparserLogFile("Line " + std::to_string($CONST_INT->getLine()) + ": factor : CONST_INT\n");
		writeIntoparserLogFile($CONST_INT->getText() + "\n");
		$var_list.add($CONST_INT->getText());
		$var_list.setLineNumber($CONST_INT->getLine());
	
	}
	| CONST_FLOAT
    {

		$var_list.set_factor_const_type("CONST_FLOAT");
        // Get the raw token text and convert to double
        std::string floatText = $CONST_FLOAT->getText();
        double floatValue = std::stod(floatText);

        // Format with two decimal places
        std::stringstream ss;
        ss << std::fixed << std::setprecision(2) << floatValue;
        std::string formattedFloat = ss.str();

        // Log the rule and formatted value
        writeIntoparserLogFile("Line " + std::to_string($CONST_FLOAT->getLine()) + ": factor : CONST_FLOAT\n");
        writeIntoparserLogFile(formattedFloat + "\n");

        // Add formatted value to var_list
        $var_list.add(formattedFloat);
        $var_list.setLineNumber($CONST_FLOAT->getLine());
    }
	| variable INCOP
	{
		writeIntoparserLogFile("Line " + std::to_string($variable.var_list.getLineNumber()) + ": factor : variable INCOP\n");
		$var_list.set_variables($variable.var_list.get_variables());
		$var_list.setLineNumber($variable.var_list.getLineNumber());
		$var_list.add( $INCOP->getText());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
	} 
	| variable DECOP
	{
		writeIntoparserLogFile("Line " + std::to_string($variable.var_list.getLineNumber()) + ": factor : variable DECOP\n");
		$var_list.set_variables($variable.var_list.get_variables());
		$var_list.setLineNumber($variable.var_list.getLineNumber());
		$var_list.add($DECOP->getText());
		writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
	}
	;

argument_list returns[str_list var_list] : arguments
{
	$var_list.set_variables($arguments.var_list.get_variables());
	$var_list.setLineNumber($arguments.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($arguments.var_list.getLineNumber()) + ": argument_list : arguments\n");
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
			  |
			  ;

arguments returns[str_list var_list]: a=arguments COMMA logic_expression
{
	$var_list.set_variables($a.var_list.get_variables());
	$var_list.add($COMMA->getText());
	$var_list.add($logic_expression.var_list.get_list_as_string());
	$var_list.setLineNumber($logic_expression.var_list.getLineNumber());
	writeIntoparserLogFile("Line " + std::to_string($logic_expression.var_list.getLineNumber()) + ": arguments : arguments COMMA logic_expression\n");
	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
}
	      | logic_expression
		  {
			$var_list.add($logic_expression.var_list.get_list_as_string());
			$var_list.setLineNumber($logic_expression.var_list.getLineNumber());
			writeIntoparserLogFile("Line " + std::to_string($logic_expression.var_list.getLineNumber()) + ": arguments : logic_expression\n");
		 	writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
		 }
	      ;