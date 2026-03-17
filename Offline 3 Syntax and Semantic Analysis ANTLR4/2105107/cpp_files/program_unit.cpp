#pragma once;
#include<string>
#include<vector>

class program_unit_list {
private:
    std::vector<std::string> program_units;
    int line_no = 0; // Line number for error reporting, if needed

public:
    // Constructor
    program_unit_list() = default;



    // getters and setters
    const std::vector<std::string>& get_variables() const {
        return program_units;
    }
    void set_variables(const std::vector<std::string>& vars) {
        program_units = vars;
    }

    // Add a string to the list
    void add(const std::string& str) {
        program_units.emplace_back(str);
    }

    // Get the size of the list
    std::string size() const {
        return std::to_string(program_units.size());
    }

    // Clear the list
    void clear() {
        program_units.clear();
    }
    // bool is_type(const std::string& s) {
    //     return (s == "int" || s == "float" || s == "void");
    // }

    std::string get_list_as_string() const {
        std::string result;
        for (const auto& var : program_units) {
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
           result +="\n";
            
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

