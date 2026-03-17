%option noyywrap
%option yylineno

%{
#include <fstream>
#include <string>
#include "symbol_table.h"

using namespace std;

// Output files
ofstream log_file("2105107_log.txt");
ofstream token_file("2105107_token.txt");

// Symbol table with 7 buckets
SymbolTable symbol_table(7);

// Counters

int error_count = 0;

// Buffer for strings and comments
string string_buffer;
string comment_buffer;



string current_const_char_text;
string current_converted_text;
// Escape special characters for token file output
string escape_for_log(const string& input) {
    string result;
    for (char c : input) {
        switch (c) {
            case '\n': result += "\\n"; break;
            case '\t': result += "\\t"; break;
            case '\\': result += "\\\\"; break;
            case '\'': result += "\\'"; break;
            case '\"': result += "\\\""; break;
            case '\0': result += "\\0"; break;
            case '\v': result += "\\v"; break;
            case '\b': result += "\\b"; break;
            case '\r': result += "\\r"; break;
            case '\f': result += "\\f"; break;
            case '\a': result += "\\a"; break;
            default: result += c; break;
        }
    }
    return result;
}

string get_special_character_ASCII(const string& input) {
    if (input.length() == 2 && input[0] == '\\') {
        switch (input[1]) {
            case 'n': return "\n";
            case 't': return "\t";
            case '\\': return "\\";
            case '\'': return "\'";
            case '\"': return "\"";
            case '0': return "\0";
            case 'v': return "\v";
            case 'b': return "\b";
            case 'r': return "\r";
            case 'f': return "\f";
            case 'a': return "\a";
            default: return input; // Invalid escape, return as-is
        }
    }
    return input; // Not an escape sequence
}

void handle_error(const string& error_type, const string& lexeme) {
    if (error_type == "UNFINISHED_CONST_CHAR") {
        log_file << "Error at line no " << yylineno << ": Unterminated character " << lexeme << endl;
    } else if (error_type == "EMPTY_CONST_CHAR") {
        log_file << "Error at line no " << yylineno << ": Empty character constant error " << lexeme<< endl << endl;
    } else if (error_type == "MULTICHAR_CONST_CHAR") {
        log_file << "Error at line no " << yylineno << ": Multi character constant error " << lexeme << endl;
    } else if (error_type == "UNRECOGNIZED_CHAR") {
        log_file << "Error at line no " << yylineno << ": Unrecognized character " << lexeme << endl;
    } else if (error_type == "TOO_MANY_DECIMAL") {
        log_file << "Error at line no " << yylineno << ": Too many decimal points " << lexeme << endl;
    } else if (error_type == "ILLFORMED_NUMBER") {
        log_file << "Error at line no " << yylineno << ": Ill formed number " << lexeme<< endl << endl;
    } else if (error_type == "INVALID_ID_SUFFIX") {
        log_file << "Error at line no " << yylineno << ": Invalid prefix on ID or invalid suffix on Number " << lexeme<< endl << endl;
    } else if (error_type == "UNFINISHED_STRING") {
        log_file << "Error at line no " << yylineno << ": Unterminated string " << lexeme<< endl << endl;
    } else if (error_type == "UNFINISHED_COMMENT") {
        log_file << "Error at line no " << yylineno << ": Unterminated comment " << lexeme<< endl << endl;
    }
    error_count++;
}

void handle_token_lexeme_pair(const pair<string, string>& token_lexeme) {
    log_file << "Line no " << yylineno << ": Token <" << token_lexeme.first << "> Lexeme " << current_const_char_text << " found" << endl;
    token_file << "<" << token_lexeme.first << "," << escape_for_log(token_lexeme.second) << ">" << endl;
    symbol_table.insert(current_const_char_text, "CONST_CHAR", "", log_file);
    symbol_table.printAllScopes(log_file);
}

void handle_current_const_char() {
    int len = current_converted_text.length();

    log_file << "Debug: current_const_char_text=" << current_const_char_text << ", current_converted_text=" << current_converted_text << ", length=" << len<< endl << endl;
    if (len == 2) {
        handle_error("EMPTY_CONST_CHAR", current_const_char_text);
    } else if (len > 3) {
        handle_error("MULTICHAR_CONST_CHAR", current_const_char_text);
    } else if (len == 3) {
        char ch = current_converted_text[1];
        if (ch == '#' || ch == '$' || ch == '@') { // Check for unrecognized characters
            handle_error("UNRECOGNIZED_CHAR", current_const_char_text);
        } else {
            handle_token_lexeme_pair({"CONST_CHAR", string(1, current_converted_text[1])});
        }
    }
}

// Process special characters
string process_special_chars(const string& input) {
    string result;
    for (size_t i = 0; i < input.length(); ++i) {
        if (input[i] == '\\' && i + 1 < input.length()) {
            ++i;
            switch (input[i]) {
                case 'n': result += '\n'; break;
                case 't': result += '\t'; break;
                case '\\': result += '\\'; break;
                case '\'': result += '\''; break;
                case '\"': result += '\"'; break;
                case 'a': result += '\a'; break;
                case 'f': result += '\f'; break;
                case 'r': result += '\r'; break;
                case 'b': result += '\b'; break;
                case 'v': result += '\v'; break;
                case '0': result += '\0'; break;
                default: result += input[i]; break;
            }
        } else {
            result += input[i];
        }
    }
    return result;
}


%}

/* Start conditions */
%x TOKENIZING_CONST_CHAR
%x TOKENIZING_STRING
%x TOKENIZING_SLASH_COMMENT
%x TOKENIZING_STAR_COMMENT

/* Pattern definitions */
DIGIT [0-9]
LETTER [a-zA-Z]
ALPHA_NUMERIC [a-zA-Z0-9_]
CONST_INT {DIGIT}+
REDUNDANT_DECIMAL {DIGIT}*\.{DIGIT}*(\.{DIGIT}*)+
DECIMAL_FRACTION \.{DIGIT}+
FLOAT_NUMBER ({DIGIT}+{DECIMAL_FRACTION}?|{DECIMAL_FRACTION})
EXPONENT [eE][+-]?{DIGIT}+
CONST_FLOAT {FLOAT_NUMBER}{EXPONENT}?
FRACTIONAL_EXPONENT [eE][+-]?{DIGIT}*\.{DIGIT}+
ILLFORMED_NUMBER {FLOAT_NUMBER}{FRACTIONAL_EXPONENT}
IDENTIFIER ({LETTER}|_)({ALPHA_NUMERIC}|_)*
INVALID_ID_SUFFIX {CONST_INT}{IDENTIFIER}
SINGLE_QUOTE "'"
DOUBLE_QUOTE "\""
BACKSLASH "\\"
NON_BACKSLASH [^\\]
SPECIAL_CHARACTER \\[nt\\\'\"0vbrfa]
NEWLINE \r\n|\n|\r

%%

"if"        { log_file << "Line no " << yylineno << ": Token <IF> Lexeme " << yytext << " found." << endl; token_file << "<IF>" <<endl; }
"else"      { log_file << "Line no " << yylineno << ": Token <ELSE> Lexeme " << yytext << " found." << endl; token_file << "<ELSE>" <<endl; }
"goto"      { log_file << "Line no " << yylineno << ": Token <GOTO> Lexeme " << yytext << " found." << endl; token_file << "<GOTO>" <<endl; }
"for"       { log_file << "Line no " << yylineno << ": Token <FOR> Lexeme " << yytext << " found." << endl; token_file << "<FOR>" <<endl; }
"while"     { log_file << "Line no " << yylineno << ": Token <WHILE> Lexeme " << yytext << " found." << endl; token_file << "<WHILE>" <<endl; }
"long"      { log_file << "Line no " << yylineno << ": Token <LONG> Lexeme " << yytext << " found." << endl; token_file << "<LONG>" <<endl; }
"do"        { log_file << "Line no " << yylineno << ": Token <DO> Lexeme " << yytext << " found." << endl; token_file << "<DO>" <<endl; }
"break"     { log_file << "Line no " << yylineno << ": Token <BREAK> Lexeme " << yytext << " found." << endl; token_file << "<BREAK>" <<endl; }
"short"     { log_file << "Line no " << yylineno << ": Token <SHORT> Lexeme " << yytext << " found." << endl; token_file << "<SHORT>" <<endl; }
"int"       { log_file << "Line no " << yylineno << ": Token <INT> Lexeme " << yytext << " found." << endl; token_file << "<INT>" <<endl; }
"char"      { log_file << "Line no " << yylineno << ": Token <CHAR> Lexeme " << yytext << " found." << endl; token_file << "<CHAR>" <<endl; }
"static"    { log_file << "Line no " << yylineno << ": Token <STATIC> Lexeme " << yytext << " found." << endl; token_file << "<STATIC>" <<endl; }
"float"     { log_file << "Line no " << yylineno << ": Token <FLOAT> Lexeme " << yytext << " found." <<endl << endl; token_file << "<FLOAT>" <<endl; }
"double"    { log_file << "Line no " << yylineno << ": Token <DOUBLE> Lexeme " << yytext << " found." << endl; token_file << "<DOUBLE>" <<endl; }
"unsigned"  { log_file << "Line no " << yylineno << ": Token <UNSIGNED> Lexeme " << yytext << " found." <<  endl; token_file << "<UNSIGNED>" <<endl; }
"void"      { log_file << "Line no " << yylineno << ": Token <VOID> Lexeme " << yytext << " found." << endl; token_file << "<VOID>" <<endl; }
"return"    { log_file << "Line no " << yylineno << ": Token <RETURN> Lexeme " << yytext << " found." << endl; token_file << "<RETURN>" <<endl; }
"switch"    { log_file << "Line no " << yylineno << ": Token <SWITCH> Lexeme " << yytext << " found." << endl; token_file << "<SWITCH>" <<endl; }
"case"      { log_file << "Line no " << yylineno << ": Token <CASE> Lexeme " << yytext << " found." << endl; token_file << "<CASE>" <<endl; }
"default"   { log_file << "Line no " << yylineno << ": Token <DEFAULT> Lexeme " << yytext << " found." << endl; token_file << "<DEFAULT>" <<endl; }
"continue"  { log_file << "Line no " << yylineno << ": Token <CONTINUE> Lexeme " << yytext << " found." << endl; token_file << "<CONTINUE>" <<endl; }


{CONST_INT} {
    string lexeme = yytext;
    log_file << "Line no " << yylineno << ": Token <CONST_INT> Lexeme " << lexeme << " found."<< endl << endl;
    token_file << "<CONST_INT," << lexeme << ">" <<endl;
    symbol_table.insert(lexeme, "CONST_INT", "", log_file);
    symbol_table.printAllScopes(log_file);
}

{CONST_FLOAT} {
    string lexeme = yytext;
    log_file << "Line no " << yylineno << ": Token <CONST_FLOAT> Lexeme " << lexeme << " found."<< endl;
    token_file << "<CONST_FLOAT," << lexeme << ">" << endl;
    symbol_table.insert(lexeme, "CONST_FLOAT", "", log_file);
    symbol_table.printAllScopes(log_file);
}

{SINGLE_QUOTE} {
    current_const_char_text.clear();
    current_converted_text.clear();
    current_const_char_text = yytext;
    current_converted_text = yytext;
    BEGIN(TOKENIZING_CONST_CHAR);
}

<TOKENIZING_CONST_CHAR>{
    {SINGLE_QUOTE} {
        current_const_char_text += yytext;
        current_converted_text += yytext;
        handle_current_const_char();
        BEGIN(INITIAL);
    }
    
    <<EOF>> {
        handle_error("UNFINISHED_CONST_CHAR", current_const_char_text);
        BEGIN(INITIAL);
    }
    {SPECIAL_CHARACTER} {
        current_const_char_text += yytext;
        current_converted_text += get_special_character_ASCII(yytext);
    }
    \\{NON_BACKSLASH} {
        current_const_char_text += yytext;
        current_converted_text += yytext; // Treat invalid escape as literal
        handle_error("UNFINISHED_CONST_CHAR", current_const_char_text);
        BEGIN(INITIAL);
    }
    {NON_BACKSLASH} {
        current_const_char_text += yytext;
        current_converted_text += yytext;
        log_file << "Debug:yytext "<<yytext<<" current_const_char_text=" << current_const_char_text << ", current_converted_text=" << current_converted_text << endl;
        // Check for multi-character constants
        if(current_const_char_text[current_const_char_text.length()-1]=='\'' || yytext=="\n"){
            if (current_const_char_text.length() > 2) {
            handle_error("MULTICHAR_CONST_CHAR", current_const_char_text);
            BEGIN(INITIAL);
        }
        }
    }
    {NEWLINE} {
        handle_error("UNFINISHED_CONST_CHAR", current_const_char_text);
        BEGIN(INITIAL);
    }
    . {
        current_const_char_text += yytext;
        current_converted_text += yytext;
        handle_error("UNRECOGNIZED_CHAR", current_const_char_text);
        BEGIN(INITIAL);
    }
    
}
{IDENTIFIER} {
    string lexeme = yytext;
    log_file << "Line no " << yylineno << ": Token <ID> Lexeme " << lexeme << " found." << endl;
    token_file << "<ID," << lexeme << ">"<<endl;
    symbol_table.insert(lexeme, "ID", "", log_file);
    symbol_table.printAllScopes(log_file);
}

"+"|"-" {
    log_file << "Line no " << yylineno << ": Token <ADDOP> Lexeme " << yytext << " found." << endl;
    token_file << "<ADDOP," << yytext << ">" <<endl;
}

"*"|"/"|"%" {
    log_file << "Line no " << yylineno << ": Token <MULOP> Lexeme " << yytext << " found." << endl;
    token_file << "<MULOP," << yytext << ">" <<endl;
}

"++"|"--" {
    log_file << "Line no " << yylineno << ": Token <INCOP> Lexeme " << yytext << " found." << endl;
    token_file << "<INCOP," << yytext << ">" <<endl;
}

"<"|"<="|">"|">="|"=="|"!=" {
    log_file << "Line no " << yylineno << ": Token <RELOP> Lexeme " << yytext << " found." << endl;
    token_file << "<RELOP," << yytext << ">"<<endl;
}

"=" {
    log_file << "Line no " << yylineno << ": Token <ASSIGNOP> Lexeme " << yytext << " found." << endl;
    token_file << "<ASSIGNOP," << yytext << ">" <<endl;
}

"&&"|"||" {
    log_file << "Line no " << yylineno << ": Token <LOGICOP> Lexeme " << yytext << " found." << endl;
    token_file << "<LOGICOP," << yytext << ">" <<endl;
}

"!" {
    log_file << "Line no " << yylineno << ": Token <NOT> Lexeme " << yytext << " found." << endl;
    token_file << "<NOT," << yytext << ">" <<endl;
}

"(" {
    log_file << "Line no " << yylineno << ": Token <LPAREN> Lexeme " << yytext << " found." << endl;
    token_file << "<LPAREN," << yytext << ">" <<endl;
}

")" {
    log_file << "Line no " << yylineno << ": Token <RPAREN> Lexeme " << yytext << " found." << endl;
    token_file << "<RPAREN," << yytext << ">" <<endl;
}

"{" {
    log_file << "Line no " << yylineno << ": Token <LCURL> Lexeme " << yytext << " found." << endl;
    token_file << "<LCURL," << yytext << ">" <<endl;
    symbol_table.enterScope();
    log_file << "\tScopeTable# " << symbol_table.getCurrentScopeId() << " created" << endl;
}

"}" {
    log_file << "Line no " << yylineno << ": Token <RCURL> Lexeme " << yytext << " found." << endl;
    token_file << "<RCURL," << yytext << ">" <<endl;
    symbol_table.exitScope(log_file);
}

"[" {
    log_file << "Line no " << yylineno << ": Token <LTHIRD> Lexeme " << yytext << " found." << endl;
    token_file << "<LTHIRD," << yytext << ">"<<endl;
}

"]" {
    log_file << "Line no " << yylineno << ": Token <RTHIRD> Lexeme " << yytext << " found." << endl;
    token_file << "<RTHIRD," << yytext << ">" <<endl;
}

"," {
    log_file << "Line no " << yylineno << ": Token <COMMA> Lexeme " << yytext << " found." << endl;
    token_file << "<COMMA," << yytext << ">"<<endl;
}

";" {
    log_file << "Line no " << yylineno << ": Token <SEMICOLON> Lexeme " << yytext << " found." << endl;
    token_file << "<SEMICOLON," << yytext << ">" <<endl;
}

{DOUBLE_QUOTE} {
    string_buffer.clear();
    string_buffer += yytext;
    BEGIN(TOKENIZING_STRING);
}

<TOKENIZING_STRING>{DOUBLE_QUOTE} {
    string_buffer += yytext;
    string processed = process_special_chars(string_buffer.substr(1, string_buffer.length() - 2));
    log_file << "Line no " << yylineno << ": Token <STRING> Lexeme " << string_buffer << " found." << endl;
    token_file << "<STRING," << escape_for_log(processed) << ">" <<endl;
    BEGIN(INITIAL);
}

<TOKENIZING_STRING>{BACKSLASH}{NEWLINE} {
    string_buffer += yytext;
    
}

<TOKENIZING_STRING>{NEWLINE} {
    log_file << "error Line no " << yylineno << ": Unfinished string " << string_buffer << endl;
    error_count++;
    
    BEGIN(INITIAL);
}

<TOKENIZING_STRING><<EOF>> {
    log_file << "error Line no " << yylineno << ": Unfinished string " << string_buffer << endl;
    error_count++;
    BEGIN(INITIAL);
}

<TOKENIZING_STRING>{SPECIAL_CHARACTER} {
    string_buffer += yytext;
}

<TOKENIZING_STRING>. {
    string_buffer += yytext;
}

"//" {
    comment_buffer.clear();
    comment_buffer += yytext;
    BEGIN(TOKENIZING_SLASH_COMMENT);
}

<TOKENIZING_SLASH_COMMENT>{BACKSLASH}{NEWLINE} {
    comment_buffer += yytext;
    /* Stay in TOKENIZING_SLASH_COMMENT to continue processing the comment */
}

<TOKENIZING_SLASH_COMMENT>{NEWLINE} {
    log_file << "Line no " << yylineno << ": Token <COMMENT> Lexeme " << comment_buffer << " found." << endl;
    BEGIN(INITIAL);
}

<TOKENIZING_SLASH_COMMENT><<EOF>> {
    log_file << "Line no " << yylineno << ": Token <COMMENT> Lexeme " << comment_buffer << " found." << endl;
    BEGIN(INITIAL);
}

<TOKENIZING_SLASH_COMMENT>. {
    comment_buffer += yytext;
}

"/*" {
    comment_buffer.clear();
    comment_buffer += yytext;
    BEGIN(TOKENIZING_STAR_COMMENT);
}

<TOKENIZING_STAR_COMMENT>\*\/ {
    comment_buffer += yytext;
    log_file << "Line no " << yylineno << ": Token <COMMENT> Lexeme " << comment_buffer << " found." << endl;
    BEGIN(INITIAL);
}

<TOKENIZING_STAR_COMMENT>{NEWLINE} {
    comment_buffer += yytext;
    
}

<TOKENIZING_STAR_COMMENT><<EOF>> {
    log_file << "Line no " << yylineno << ":error Unfinished comment " << comment_buffer << endl;
    error_count++;
    BEGIN(INITIAL);
}

<TOKENIZING_STAR_COMMENT>. {
    comment_buffer += yytext;
}



[ \t\f\v]*{NEWLINE} {  }
[ \t\f\v]+ { } 






{REDUNDANT_DECIMAL} {
    log_file << "Line no " << yylineno << ":error Too many decimal point error for character sequence " << yytext << endl;
    error_count++;
}

{ILLFORMED_NUMBER} {
    log_file << "Line no " << yylineno << ":error Ill formed number such as " << yytext << endl;
    error_count++;
}

{INVALID_ID_SUFFIX} {
    log_file << "Line no " << yylineno << ": error Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence " << yytext << endl;
    error_count++;
}



"''" {
    log_file << "Line no " << yylineno << ":error Empty character constant error" << endl;
    error_count++;
}

. {
    log_file << "Line no " << yylineno << ":error Unrecognized character " << yytext << endl;
    error_count++;
}

%%

int main(int argc, char* argv[]) {
    if (argc != 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        cerr << "Error opening input file" << endl;
        return 1;
    }

    yyin = input_file;
    yylineno=1;
    yylex();

    /* scope_table.printAllScopes(log_file); */

    log_file << endl << "Total Lines: " << yylineno << endl;
    /* log_file<<"total line by yylineno" << yylineno <<endl; */
    log_file << "Total Errors: " << error_count << endl;

    fclose(input_file);
    log_file.close();
    token_file.close();
    return 0;
}