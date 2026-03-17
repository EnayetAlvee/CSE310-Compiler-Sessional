#pragma once;
#include<string>
#include<vector>
#include<utility> // for std::pair
using namespace std;
class paramList {
private:
    std::vector<pair<string,string>> variables;
    int line_no = 0; // Line number for error reporting, if needed

public:
    // Constructor
    paramList() = default;



    // getters and setters
    vector<pair<string,string>> get_variables()  {
        return variables;
    }
    void set_variables(vector<pair<string,string>> vars) {
        variables = vars;
    }

    // Add a string to the list
    // void add(const std::pair<string,string>& var) {
    //     variables.emplace_back(var);
    // }
    void add(const string& type, const string& name) {
        pair<string, string> var(type, name);
        variables.emplace_back(var);
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
        for(int i = 0; i < variables.size(); i++) {
            const auto& var = variables[i];
            result += var.first + " " + var.second; // Assuming first is type and second is name
            if (i < variables.size() - 1) {
                result += ","; // Add a comma between variables
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

