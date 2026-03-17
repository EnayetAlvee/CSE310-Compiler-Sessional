// symbol_table.h
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <bits/stdc++.h>
using namespace std;

class SymbolInfo {
private:
    string name;
    string type;
    SymbolInfo* next;

public:
    SymbolInfo(string name, string type) : name(name), type(type), next(nullptr) {}
    ~SymbolInfo() { next = nullptr; }

    string getName() const { return name; }
    string getType() const { return type; }
    void setName(const string& n) { name = n; }
    void setType(const string& t) { type = t; }
    SymbolInfo* getNext() const { return next; }
    void setNext(SymbolInfo* n) { next = n; }

    string additionalInfo;

    void setAdditionalInfo(const string& info) { additionalInfo = info; }
    string getAdditionalInfo() const { return additionalInfo; }
};

class ScopeTable {
private:
    SymbolInfo** buckets;
    unsigned int num_buckets;
    ScopeTable* parentScope;
    int id;

    unsigned int SDBMHash(const string& str) {
        unsigned int hash = 0;
        for (char c : str) {
            hash = (c + (hash << 6) + (hash << 16) - hash) ;
        }
        return hash % num_buckets  ;
    }



    // unsigned int SDBMHash(const char* p) {
    //         unsigned int hash = 0;
    //         auto *str = (unsigned char *) p;
    //         int c{};
    //         while ((c = *str++)) {
    //         hash = c + (hash << 6) + (hash << 16) - hash;
    //         }
    //         return hash;
    // }




public:
    ScopeTable(int n, int id, ScopeTable* parent = nullptr) : num_buckets(n), id(id), parentScope(parent) {
        buckets = new SymbolInfo*[num_buckets]();
        for (unsigned int i = 0; i < num_buckets; i++) {
            buckets[i] = nullptr;
        }
    }

    ~ScopeTable() {
        for (unsigned int i = 0; i < num_buckets; i++) {
            SymbolInfo* current = buckets[i];
            while (current) {
                SymbolInfo* temp = current;
                current = current->getNext();
                delete temp;
            }
        }
        delete[] buckets;
    }

    pair<bool, pair<int, int>> insert(const string& name, const string& type, const string& additionalInfo = "") {
        unsigned int index = SDBMHash(name);
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int pos = 1;

        while (current) {
            if (current->getName() == name) {
                return {false, {index + 1, pos}}; // Symbol already exists
            }
            prev = current;
            current = current->getNext();
            pos++;
        }

        SymbolInfo* newSymbol = new SymbolInfo(name, type);
        if (!additionalInfo.empty()) {
            newSymbol->setAdditionalInfo(additionalInfo);
        }

        if (prev) {
            prev->setNext(newSymbol);
        } else {
            buckets[index] = newSymbol;
        }
        return {true, {index + 1, pos}};
    }

    pair<SymbolInfo*, pair<int, int>> lookup(const string& name) {
        unsigned int index = SDBMHash(name);
        SymbolInfo* current = buckets[index];
        int pos = 1;
        while (current) {
            if (current->getName() == name) {
                return {current, {index + 1, pos}};
            }
            current = current->getNext();
            pos++;
        }
        return {nullptr, {index + 1, 0}};
    }

    pair<bool, pair<int, int>> remove(const string& name) {
        unsigned int index = SDBMHash(name);
        SymbolInfo* current = buckets[index];
        SymbolInfo* prev = nullptr;
        int pos = 1;

        while (current) {
            if (current->getName() == name) {
                if (prev) {
                    prev->setNext(current->getNext());
                } else {
                    buckets[index] = current->getNext();
                }
                delete current;
                return {true, {index + 1, pos}};
            }
            prev = current;
            current = current->getNext();
            pos++;
        }
        return {false, {index + 1, 0}};
    }

    void print(ostream& out, int indent = 0) {
        bool empty = true;
        for (unsigned int i = 0; i < num_buckets; i++) {
            if (buckets[i]) {
                empty = false;
                break;
            }
        }
        if (empty) return;

        // for (int i = 0; i < indent; i++) out << "\t";
        out << "ScopeTable# " << id << endl;
        for (unsigned int i = 0; i < num_buckets; i++) {
            if (!buckets[i]) continue;
            // for (int j = 0; j < indent; j++) out << "\t";
            out << (i ) << "--> ";
            SymbolInfo* current = buckets[i];
            while (current) {
                out << "<" << current->getName() << ":" << current->getType();
                if (!current->getAdditionalInfo().empty()) {
                    out << "," << current->getAdditionalInfo();
                }
                out << "> ";
                current = current->getNext();
            }
            out << endl;
        }
    }

    ScopeTable* getParentScope() const { return parentScope; }
    int getId() const { return id; }

    unsigned int getBucketIndex(const string& name) {
        return SDBMHash(name);
    }
};

class SymbolTable {
private:
    ScopeTable* currentScope;
    int scopeCount;
    int num_buckets;

public:
    SymbolTable(int n) : num_buckets(n), scopeCount(0) {
        enterScope();
    }

    ~SymbolTable() {
        while (currentScope) {
            ScopeTable* temp = currentScope;
            currentScope = currentScope->getParentScope();
            delete temp;
        }
    }

    void enterScope() {
        ScopeTable* newScope = new ScopeTable(num_buckets, ++scopeCount, currentScope);
        currentScope = newScope;
    }

    bool exitScope(ostream& out) {
        if (!currentScope || scopeCount == 1) {
            return false;
        }
        ScopeTable* temp = currentScope;
        currentScope = currentScope->getParentScope();
        out << "\tScopeTable# " << temp->getId() << " removed" << endl;
        delete temp;
        return true;
    }

    bool insert(const string& name, const string& type, const string& additionalInfo, ostream& out) {
        if (!currentScope) return false;
        auto result = currentScope->insert(name, type, additionalInfo);
        if (result.first) {
            // out << "\tInserted in ScopeTable# " << currentScope->getId() << " at position " << result.second.first << ", " << result.second.second << endl;
        } else {
            out << "\t'" << name << "' already exists in the current ScopeTable" << " at position " << result.second.first << ", " << result.second.second << endl;
        }
        return result.first;
    }

    bool remove(const string& name, ostream& out) {
        if (!currentScope) return false;
        auto result = currentScope->remove(name);
        if (result.first) {
            out << "\tDeleted '" << name << "' from ScopeTable# " << currentScope->getId() << " at position " << result.second.first << ", " << result.second.second << endl;
        } else {
            out << "\tNot found in the current ScopeTable" << endl;
        }
        return result.first;
    }

    SymbolInfo* lookup(const string& name, ostream& out, int& scopeId, pair<int, int>& pos) {
        ScopeTable* scope = currentScope;
        while (scope) {
            auto result = scope->lookup(name);
            if (result.first) {
                scopeId = scope->getId();
                pos = result.second;
                return result.first;
            }
            scope = scope->getParentScope();
        }
        scopeId = currentScope->getId();
        pos = {0, 0};
        return nullptr;
    }

    unsigned int getBucketIndexForSymbol(const string& name) {
        ScopeTable* scope = currentScope;
        while (scope) {
            auto result = scope->lookup(name);
            if (result.first) {
                return scope->getBucketIndex(name);
            }
            scope = scope->getParentScope();
        }
        return 0;
    }

    void printCurrentScope(ostream& out) {
        if (currentScope) {
            currentScope->print(out, 1);
        }
    }

    void printAllScopes(ostream& out) {
        ScopeTable* scope = currentScope;
        int indent = 1;
        while (scope) {
            scope->print(out, indent);
            scope = scope->getParentScope();
            indent++;
        }
    }

    int getCurrentScopeId() const {
        return currentScope ? currentScope->getId() : 0;
    }
};

#endif