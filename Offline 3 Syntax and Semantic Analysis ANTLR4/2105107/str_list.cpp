#pragma once;
#include<string>
#include<vector>
using namespace std;
class str_list {
private:
    std::string factor_const_type;   //only for const
    std::vector<std::string> variables;
    int line_no = 0; // Line number for error reporting, if needed

public:
    // Constructor
    str_list() = default;

    

    void set_factor_const_type(const std::string& type) {
        factor_const_type = type;
    }
    std::string get_factor_const_type() const {
        return factor_const_type;
    }

    // getters and setters
    const std::vector<std::string>& get_variables() const {
        return variables;
    }
    void set_variables(const std::vector<std::string>& vars) {
        variables = vars;
    }

    // Add a string to the list
    void add(const std::string& str) {
        variables.emplace_back(str);
    }

    // Get the size of the list
    std::string size() const {
        return std::to_string(variables.size());
    }

    // Clear the list
    void clear() {
        variables.clear();
    }
    // bool is_type(const std::string& s) {
    //     return (s == "int" || s == "float" || s == "void");
    // }

    std::string get_list_as_string() const {
        std::string result;
        for (const auto& var : variables) {
            // std::cout<<"var: "<<var<<std::endl;
            // if (!result.empty() && var!=";") {
            //     // std::cout<<"var: "<<var<<std::endl;
            //     // if(var=="int" || var=="float"||var=="void"){
            //     //     result += " ";
            //     // }
            //     // else {
            //     //     result += ", ";
            //     // }
            //     result += ",";
            // }
            result += var;
            if( (var=="int" || var=="float" || var=="void")) {
                result += " ";
            }
            
        }
        return result;
    }

    int getLineNumber() const {
        return line_no;
    }
    void setLineNumber(int line) {
        line_no = line;
    }

};



class statements_str_for_print{
private:
    std::vector<std::string> statements;
    // int line_no = 0; // Line number for error reporting, if needed
    public:
    std::string get_list_as_string() const {
        std::string result;
        for (const auto& statement : statements) {
            result += statement + "\n"; // Assuming each statement ends with a newline
        }
        return result;
    }
    void add(const std::string& statement) {
        statements.emplace_back(statement);
    }
    void set_variables(const std::vector<std::string>& vars) {
        statements = vars;
    }
    const std::vector<std::string>& get_variables() const {
        return statements;
    }

};



class variable_type_list {
private:
    std::string factor_const_type;   //only for const
    std::vector<std::string> variables;
    int line_no = 0; // Line number for error reporting, if needed

public:
    // Constructor
    variable_type_list() = default;

    string variable_id_name;
    string variable_id_type;

    

    void set_factor_const_type(const std::string& type) {
        factor_const_type = type;
    }
    std::string get_factor_const_type() const {
        return factor_const_type;
    }

    // getters and setters
    const std::vector<std::string>& get_variables() const {
        return variables;
    }
    void set_variables(const std::vector<std::string>& vars) {
        variables = vars;
    }

    // Add a string to the list
    void add(const std::string& str) {
        variables.emplace_back(str);
    }

    // Get the size of the list
    std::string size() const {
        return std::to_string(variables.size());
    }

    // Clear the list
    void clear() {
        variables.clear();
    }
    

    std::string get_list_as_string() const {
        std::string result;
        for (const auto& var : variables) {
            
            result += var;
            if( (var=="int" || var=="float" || var=="void")) {
                result += " ";
            }
            
        }
        return result;
    }

    int getLineNumber() const {
        return line_no;
    }
    void setLineNumber(int line) {
        line_no = line;
    }

};
