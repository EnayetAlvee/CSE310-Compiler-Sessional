#include <iostream>
#include <sstream>

using namespace std;

int collision_count=0;

unsigned int FNV1aHash(const std::string& str,int num_buckets) {
    const unsigned int FNV_OFFSET_BASIS = 2166136261u;  // FNV offset basis
    const unsigned int FNV_32_PRIME = 16777619u;  // FNV prime number
    unsigned int hash = FNV_OFFSET_BASIS;

    for (char c : str) {
        hash ^= static_cast<unsigned int>(c); // XOR the character
        hash *= FNV_32_PRIME; // Multiply by the FNV prime
    }
    return (hash%num_buckets)+1;
}



unsigned int DJB3Hash(const std::string& str,int num_buckets) {
    unsigned int hash = 5381;
    for (char c : str) {
        hash = ((hash << 5) + hash) + c; // hash * 33 + c
    }
    return (hash % num_buckets)+ 1;
}




class SymbolInfo
{
private:
    string Name;
    string Type;
    SymbolInfo *next = nullptr;

public:
    void setName(string str){
        Name = str;
    }
    string getName() {
        return Name;
    }
    void setType(string str){
        Type = str;
    }
    
    string getType() {
        return Type;
    }
    void setNext(SymbolInfo *n) {
        next = n;
    }
    SymbolInfo *getNext() {
        return next;
    }
};

unsigned int SDBMHash(string str, unsigned int num_buckets)
{
    unsigned int hash = 0;

    unsigned int len = str.length();

    for (unsigned int i = 0; i < len; i++)
    {
        hash = ((str[i]) + (hash << 6) + (hash << 16) - hash) %
               num_buckets;
    }
    hash++;

    return hash;   
}


class ScopeTable {
    private:
    int no_of_buckets;
    int ID;
    SymbolInfo **scopeTable;
    ScopeTable *parentScope;

public:
    ScopeTable(int buckets, ScopeTable *parent = nullptr) : no_of_buckets(buckets), parentScope(parent) {
        scopeTable = new SymbolInfo*[no_of_buckets+1];
        for (int i = 1; i <= no_of_buckets; i++) {
            scopeTable[i] = nullptr;
        }
    }
    void setId(int id) {
        ID = id;
    }
    int getID() {
        return ID;
    }
    void setParent(ScopeTable *parent) {
        parentScope = parent;
    }

    ScopeTable *getParent() {
        return parentScope;
    }


    bool Insert(string name, string type) {
        if(LookUp(name) != nullptr) {
            cout << name << " already exists in the current ScopeTable" << endl;
            return false; // Symbol already exists
        }
        int pos=1;
        unsigned int index = SDBMHash(name, no_of_buckets);
        // cout<<"index: "<<index<<endl;
        //need to store at last of the index
        SymbolInfo *current= scopeTable[index];
        if(current == nullptr) {
            // cout<<"in here "<<endl;
            scopeTable[index] = new SymbolInfo();
            scopeTable[index]->setName(name);
            scopeTable[index]->setType(type);
            // cout<<"scopetable index : "<<scopeTable[index]->getName()<<endl;
        } 
        else {
            while (current->getNext() != nullptr) {
                collision_count++;
                pos++;
                current = current->getNext();
            }
            pos++;  
            current->setNext(new SymbolInfo());
            current->getNext()->setName(name);
            current->getNext()->setType(type);
        }
        cout << "Inserted in ScopeTable# " << getID() << " at position " << index<<", "<<pos << endl;

        return true;
    }

    SymbolInfo *LookUp(string name) {
        unsigned int index = SDBMHash(name, no_of_buckets);
        int pos=1;
        SymbolInfo *current = scopeTable[index];
        while (current != nullptr) {
            //  cout<<"current name: "<<current->getName()<<endl;
            //  cout<<"in here "<<(current->getName() == name)<<endl;
            if (current->getName() == name) {
                // cout<<"in here"<<endl;
                cout <<name<< " found in ScopeTable# " << getID() << " at position " << index<<", "<<pos << endl;
                return current;
            }
            current = current->getNext();
            pos++;
        }
        return nullptr;
    }

    bool Delete(string name){
        unsigned int index = SDBMHash(name, no_of_buckets);
        SymbolInfo *current = scopeTable[index];
        SymbolInfo *prev = nullptr;
        int pos=1;
        while (current != nullptr) {
            if (current->getName() == name) {
                if (prev == nullptr) {
                    scopeTable[index] = current->getNext();
                } else {
                    prev->setNext(current->getNext());
                }
                cout<<"Deleted "<<name<<" from ScopeTable# " << getID() << " at position " << index<<", "<<pos<<endl;
                delete current;
                return true;
            }
            pos++;
            prev = current;
            current = current->getNext();
        }
        cout<<"Not found in the current ScopeTable"<<endl;
        return false; // Symbol not found
    }


    void Print() {
        cout << "\tScopeTable# " << getID() << endl;
        for (int i = 1; i <= no_of_buckets; i++) {
            cout <<"\t" << i << " --> ";
            SymbolInfo *current = scopeTable[i];
            while (current != nullptr) {
                cout << "<" << current->getName() << ", " << current->getType() << "> ";
                current = current->getNext();
            }
            cout << endl;
        }
    }
    ~ScopeTable() {
        // Iterate through all buckets and delete all linked SymbolInfo objects
        for (int i = 1; i <= no_of_buckets; i++) {
            SymbolInfo *current = scopeTable[i];
            while (current != nullptr) {
                SymbolInfo *temp = current;
                current = current->getNext();
                delete temp;  // delete each SymbolInfo object
            }
        }
        delete[] scopeTable;  // Delete the array of pointers
    }
    
    // void printc() {
    //     printf("\tScopeTable# %u\n", ID);
    //     for (unsigned int i = 1; i <= no_of_buckets; ++i) {
    //         printf("\t%u-->", i);
    //         SymbolInfo* cur = scopeTable[i];
    //         for (; cur; cur = cur->getNext()) {
    //             const auto& t = cur->getType();
    //             if (t.rfind("STRUCT ", 0) == 0 || t.rfind("UNION ", 0) == 0) {
    //                 // printStructured is undefined, replace with default print
    //                 printf(" <%s,%s>", cur->getName().c_str(), t.c_str());
    //             } else {
    //                 // default print
    //                 printf(" <%s,%s>", cur->getName().c_str(), t.c_str());
    //             }
    //         }
    //         printf("\n");
    //     }
    // }

    


};



// -------------- SymbolTable Class --------------
class SymbolTable {
    private:
        ScopeTable *currentScope;
        int bucketCount;
        int scopeCount;
    public:
    
        ScopeTable *getCurrentScope() {
            return currentScope;
        }
    
        SymbolTable(int bucketCount) : bucketCount(bucketCount) {
            currentScope = nullptr;
            EnterScope();
        }
        void EnterScope() {
            currentScope = new ScopeTable(bucketCount, currentScope); //bucket_size and parentScope
            currentScope->setId(++scopeCount);
            cout << "\t\tScopeTable# " << currentScope->getID() << " created" << endl;
        }
    
        void ExitScope(){
            if(currentScope == nullptr) {
                cout << "No ScopeTable to exit" << endl;
                return;
            }
            // if(currentScope->getParent() == NULL)
            // {
            //     // because the first scope (created due to main)
            //     // can not be exited
            //     return;
            // }
            ScopeTable *temp = currentScope;
            currentScope = currentScope->getParent(); 
            cout << "ScopeTable# " << temp->getID() << " removed" << endl;
            // temp->setParent(nullptr); // set parent to null to avoid dangling pointer
            // cout<<" all good here"<<endl;
            temp->~ScopeTable(); // delete the current scope table
            
            // delete temp; // free the memory allocated for the current scope table
        }
       
    
        bool Insert(string name, string type) {
            if(currentScope == nullptr) {
                cout << "No ScopeTable to insert into" << endl;
                return false;
            }
            return currentScope->Insert(name, type);
        }
        bool Remove(string name) {
            if(currentScope == nullptr) {
                cout << "No ScopeTable to remove from" << endl;
                return false;
            }
            return currentScope->Delete(name);
        }
        
    
    
        void PrintCurrentScope() {
            if(currentScope != nullptr) {
                currentScope->Print();
            } else {
                cout << "No current ScopeTable to print" << endl;
            }
        }
    
    
        void PrintAllScopes() {
            ScopeTable *temp = currentScope;
            while(temp != nullptr) {
                temp->Print();
                temp = temp->getParent();
            }
        }

        ~SymbolTable()
        {
            while(currentScope!=nullptr){
                // currentScope->Print();
                ExitScope();
                currentScope = currentScope->getParent();
            }
            


            // while(currentScope != nullptr)
            // {
            //     // cout<<"in here"<<endl;
            //     // ScopeTable* temp = currentScope;
            //     ExitScope();
            //     cout<<""<<currentScope<<" "<<currentScope->getParent();
                
            //     currentScope = currentScope->getParent();
            //     // printf("%d",currentScope);
            //     // delete temp;
            // }
        }
       
        
        SymbolInfo* lookup(string name)
        {
            ScopeTable* curr = getCurrentScope();
            while(curr != nullptr)
            {
                SymbolInfo* existing_entry = curr->LookUp(name);
                if(existing_entry != nullptr)
                {
                    //so, found in this scopetable
                    return existing_entry;
                }
                curr = curr->getParent() ; //go to parent scope
            }
            cout<<""<<name<<" not found in any of the ScopeTables"<<endl;
            return nullptr;
        }
    };
    
    

int main(){
    freopen("output.txt", "w", stdout);
    freopen("input.txt", "r", stdin);
    int bucket_size;
    cin >> bucket_size;

    cin.ignore();
    SymbolTable *symbolTable=new SymbolTable(bucket_size);
    string choice;
    string line;
    

    int cmd_count=0;

    while(getline(cin,line)){

        if(line=="") continue;

        stringstream string_stream(line);
        string command;
        string  arg[3];

        string_stream >> command;


        // cout<<"here for debugging"  <<endl;
        // cout<<command<<endl;
        // // cout<<line<<endl;
        

        string temp;
        int arg_cnt=0;
        while (string_stream >> temp ) {
            if(arg_cnt<3)
        	    arg[arg_cnt] = temp;
        	arg_cnt++;
        }


        
        // string error_arg_cnt = "Wrong number of arguments for the command ";



        // cout<<"args: "<<arg[0]<<arg[1]<<arg[2]<<endl;

        int expected_arg_count;

        ScopeTable *currentScopeTable = symbolTable->getCurrentScope();
        int current_scopetable_id=currentScopeTable->getID();
        cmd_count++;

        cout<<"Cmd "<<cmd_count<<": "<<line<<endl;

        if(command=="I" || command=="L" || command =="D" || command=="E" || command =="Q"){
            // cout<<"in here"<<endl;
            cout<<"\t \t";
        }
        

        if(command == "I")
        {
        	// expected_arg_count = 2;

        	// if(arg_count != expected_arg_count)
        	// {
        	//  	cout<<error_arg_cnt<<command<<endl;
        	//  	continue;
        	// }

        	string name = arg[0];
        	string type = arg[1];

            // cout<<"name: "<<name<<" type<: "<<type<<endl;

        	symbolTable->Insert(name, type);

        }
        else if(command == "L")
        {
        	expected_arg_count = 1;

        	if(arg_cnt != expected_arg_count)
        	{
        	 	cout<<"Number of parameters mismatch for the command "<<command<<endl;
        	 	continue;
        	}

        	string name = arg[0];
            SymbolInfo *symbolInfo = symbolTable->lookup(name);


        }
        else if(command == "D")
        {
        	expected_arg_count = 1;

        	if(arg_cnt != expected_arg_count)
        	{
        	 	cout<<"Number of parameters mismatch for the command "<<command<<endl;
        	 	continue;
        	}
        	string name = arg[0];

        	symbolTable->Remove(name);
        }
        else if(command == "P")
        {
        	// expected_arg_count = 1;

        	// if(arg_count != expected_arg_count)
        	// {
        	//  	cout<<error_arg_cnt<<command<<endl;
        	//  	continue;
        	// }

        	string operation = arg[0];

        	if(operation == "A")
        	{
        		symbolTable->PrintAllScopes();
        	}
        	else if(operation == "C")
        	{
        		symbolTable->PrintCurrentScope();
        	}
        	else
        	{
        		cout<<"\tInvalid argument for the command P";
        		cout<<endl;
        	}
        }
        else if(command == "S")
        {
        	// expected_arg_count = 0;

        	// if(arg_count != expected_arg_count) // corrected from arg_cnt to arg_count
        	// {
        	//  	cout<<error_arg_cnt<<command<<endl;
        	//  	continue;
        	// }
            // cout<<"i got S here"<<endl;
        	symbolTable->EnterScope();
        }
        else if(command == "E")
        {
        	// expected_arg_count = 0;

        	// if(arg_count != expected_arg_count) // corrected from arg_cnt to arg_count
        	// {
        	//  	cout<<error_arg_cnt<<command<<endl;
        	//  	continue;
        	// }

        	if(current_scopetable_id == 1)
        	{
        		cout<<"\tScopeTable# 1 cannot be deleted"<<endl;
        		continue;
        	}
        	symbolTable->ExitScope();
            // cout<<"E completed"<<endl;
        }
        else if(command == "Q")
        {
        	// expected_arg_count = 0;

        	// if(arg_count != expected_arg_count)
        	// {
        	//  	cout<<error_arg_cnt<<command<<endl;
        	//  	continue;
        	// }
        	symbolTable->~SymbolTable(); 
            cout<<"collision count: "<<collision_count<<endl;
        	break;
        }
    }
    fflush(stdout);  


    return 0;
}


