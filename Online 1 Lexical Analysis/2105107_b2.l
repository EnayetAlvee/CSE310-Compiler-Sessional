%{
#include<iostream>              // Include input/output stream library
#include<string>                // Include string library
#include<cstdio>                // Include C standard I/O library
#include<stack>                 // Include stack library for bracket matching

using namespace std;            // Use the standard namespace

int line_count=1;               // Initialize line counter to 1
string current_lexeme="";       // String to store the current lexeme being processed
stack<int> bracket_stack;       // Stack to keep track of nested angle brackets
bool is_valid=true;             // Flag to check if the vector type is valid
bool processed_vector=false;    // Flag to check if a vector type was processed in the current line
bool reported=false;            // Flag to check if an error or token was already reported for the current line

// Function to reset the state variables for a new line or after processing a vector type
void reset_state(){
    current_lexeme="";          // Clear the current lexeme
    while(!bracket_stack.empty()){
        bracket_stack.pop();    // Empty the bracket stack
    }
    is_valid=true;              // Reset validity flag
}

%}

%option noyywrap                

%x LATEX_STATE                 

WHITESPACE [ \t]                
NEWLINE \n|\r\n                 
TYPE "\\textbf"|"\\textit"|"\\section"
%%



^{WHITESPACE}*{TYPE}{WHITESPACE}*"{" {
    // cout<<"1"<<endl;
    bracket_stack.push(1);
    // Start of a vector type declaration at the beginning of a line
    current_lexeme=yytext;          // Store the matched text
    // bracket_stack.push(1);          // Push to stack for '{'
    // is_vald=false;                  // Assume valid until proven otherwise
    // processed_vector=true;          // Mark that a vector is being processed
    // reported=false;                 // Reset reported flag
    BEGIN(LATEX_STATE);            // Switch to LATEX_STATE for further parsing
}

<LATEX_STATE>{TYPE}{WHITESPACE}*"{" {
    bracket_stack.push(1);

// cout<<"3"<<endl;
}

<LATEX_STATE>"}" {
    // cout<<"2"<<endl;
    if(!bracket_stack.empty() ){
        bracket_stack.pop();
    }
    // else{
    //     cout<<"error: mismatched {"<<endl;
    // }
}




{WHITESPACE}+ {
    // Ignore whitespace outside vector type
}

{NEWLINE} {
    // cout<<"4"<<endl;
    // Handle end of line
    if(!bracket_stack.empty()){
        cout<<"Error: unmatched{ "<<endl;
        // If brackets are not balanced, report error
        // cout << "Line No. " << line_count << ": Error in <VECTOR_TYPE> declaration" << endl;
    }
    else{
        cout<<"line no : "<<yylineno <<"matched"<<endl;
    }
    line_count++;                   // Move to next line
    processed_vector=false;         // Reset processed_vector flag
    reported=false;                 // Reset reported flag
    BEGIN(INITIAL);                 // Return to INITIAL state
}

. {

}



%%

int main(int argc, char **argv) {
    if (argc != 3) {            // Check for correct number of arguments
        cerr << "Usage: " << argv[0] << " input_file output_file" << endl;
        return 1;
    }

    FILE *inputFile = fopen(argv[1], "r"); // Open input file for reading
    if (inputFile == NULL) {    // Check if file opened successfully
        cerr << "Error opening input file." << endl;
        return 1;
    }

    if (freopen(argv[2], "w", stdout) == NULL) { // Redirect stdout to output file
        cerr << "Error opening output file." << endl;
        fclose(inputFile);
        return 1;
    }

    yyin = inputFile;           // Set lex input to input file
    yylex();                    // Start lexical analysis

    fclose(inputFile);          // Close input file
    fclose(stdout);             // Close output file

    return 0;                   // Exit program
}