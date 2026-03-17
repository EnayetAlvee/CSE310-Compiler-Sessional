#pragma once;
#include<string>
#include<vector>

class comp_statement_list {
private:
    std::vector<std::string> statement_variable;
    int line_no = 0; // Line number for error reporting, if needed

public:
    // Constructor
    comp_statement_list() = default;



    // getters and setters
    const std::vector<std::string>& get_statement_variable() const {
        return statement_variable;
    }
    void set_statement_variable(const std::vector<std::string>& vars) {
        statement_variable = vars;
    }

    // Add a string to the list
    void add(const std::string& str) {
        statement_variable.emplace_back(str);
    }

    // Get the size of the list
    std::string size() const {
        return std::to_string(statement_variable.size());
    }

    // Clear the list
    void clear() {
        statement_variable.clear();
    }

    std::string get_list_as_string() const {
        std::string result;
        for (const auto& var : statement_variable) {
            result += var;
            result+= "\n"; // Assuming each statement ends with a newline
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

