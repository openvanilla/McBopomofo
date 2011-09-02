//
// OVSQLiteDatabaseService.h
//
// Copyright (c) 2007-2010 Lukhnos D. Liu
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#ifndef OVSQLiteDatabaseService_h
#define OVSQLiteDatabaseService_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVDatabaseService.h>
    #include <OpenVanilla/OVSQLiteWrapper.h>
	#include <OpenVanilla/OVWildcard.h>
#else
    #include "OVDatabaseService.h"
    #include "OVSQLiteWrapper.h"
	#include "OVWildcard.h"
#endif

namespace OpenVanilla {
    using namespace std;
    
    class OVSQLiteHelper {
    public:
        static const pair<string, string> SQLiteStringFromWildcard(const OVWildcard& wildcard)
        {
            const string& expression = wildcard.expression();
            string sqlstr;
            
            char mOC = wildcard.matchOneChar();
            char mZOMC = wildcard.matchZeroOrMoreChar();
            char escChar = mZOMC ? mZOMC : mOC;
                        
            for (string::const_iterator iter = expression.begin() ; iter != expression.end() ; ++iter) {
                if (*iter == mOC) {
                    sqlstr += '_';
                }
                else if (*iter == mZOMC) {
                    sqlstr += '%';
                }
                else if (*iter == '_') {
                    sqlstr += escChar;
                    sqlstr += '_';
                }
                else if (*iter == '%') {
                    sqlstr += escChar;
                    sqlstr += '%';         
                }
                else {
                    sqlstr += *iter;
                }
            }
            
            return pair<string, string>(sqlstr, string(1, escChar));
        }
    };
    
    class OVSQLiteDatabaseService;
    
    class OVSQLiteKeyValueDataTable : public OVKeyValueDataTableInterface {
    public:
        virtual const vector<string> valuesForKey(const string& key);
        virtual const vector<pair<string, string> > valuesForKey(const OVWildcard& expression);
        virtual const string valueForProperty(const string& property);
        virtual const vector<string> keysForValue(const string& value);
        
    protected:
        OVSQLiteDatabaseService* m_source;
        string m_tableName;

        friend class OVSQLiteDatabaseService;
        OVSQLiteKeyValueDataTable(OVSQLiteDatabaseService* source, const string& tableName)
            : m_source(source)
            , m_tableName(tableName)
        {
        }
    };

    class OVSQLiteDatabaseService : public OVDatabaseService {
    public:
        ~OVSQLiteDatabaseService()
        {
            if (m_ownsConnection)
                delete m_connection;
        }
        
        virtual const vector<string> tables(const OVWildcard& filter = string("*"))
        {
            pair<string, string> exp = OVSQLiteHelper::SQLiteStringFromWildcard(filter);
                        
            vector<string> result;
            OVSQLiteStatement* statement = m_connection->prepare("SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE %Q ESCAPE %Q ORDER BY name", exp.first.c_str(), exp.second.c_str());
            if (statement) {
                while (statement->step() == SQLITE_ROW) {
                    result.push_back(statement->textOfColumn(0));
                }
                
                delete statement;
            }
            
            return result;            
        }

        virtual bool tableSupportsValueToKeyLookup(const string &tableName)
        {
            return true;
        }        
        
        virtual OVKeyValueDataTableInterface* createKeyValueDataTableInterface(const string& name, bool suggestedCaseSensitivity = false)
        {
            return new OVSQLiteKeyValueDataTable(this, name);
        }
        
        virtual const string valueForPropertyInTable(const string& property, const string& name)
        {
            OVSQLiteStatement* statement = m_connection->prepare("SELECT VALUE FROM %Q WHERE KEY = ?", name.c_str());
            string result;
            
            if (statement) {
                statement->bindTextToColumn(string(OVPropertyStringInternalPrefix) + property, 1);
                
                if (statement->step() == SQLITE_ROW) {
                    result = statement->textOfColumn(0);
                    while (statement->step() == SQLITE_ROW) ;
                }

                delete statement;
            }
            
            return result;
        }

		virtual const string filename()
		{
			return m_connection->filename();
		}

        static OVSQLiteDatabaseService* Create(const string& filename = ":memory:")
        {
            OVSQLiteConnection* connection = OVSQLiteConnection::Open(filename);
            if (!connection)
                return 0;
                
            return new OVSQLiteDatabaseService(connection, true);
        }
        
        static OVSQLiteDatabaseService* ServiceWithExistingConnection(OVSQLiteConnection* connection, bool ownsConnection = false)
        {
            return new OVSQLiteDatabaseService(connection, ownsConnection);
        }

        OVSQLiteConnection* connection()
        {
            return m_connection;
        }

    protected:
        friend class OVSQLiteKeyValueDataTable;
        
        OVSQLiteDatabaseService(OVSQLiteConnection* connection, bool ownsConnection = false)
            : m_connection(connection)
            , m_ownsConnection(ownsConnection)
        {
        }
        
        OVSQLiteConnection* m_connection;
        bool m_ownsConnection;
    };

    inline const vector<string> OVSQLiteKeyValueDataTable::valuesForKey(const string& key)
    {
        vector<string> result;
        OVSQLiteStatement* statement = m_source->connection()->prepare("SELECT value FROM %Q WHERE key = %Q", m_tableName.c_str(), key.c_str());
        if (statement) {
            while (statement->step() == SQLITE_ROW) {
                result.push_back(statement->textOfColumn(0));
            }
            
            delete statement;
        }
        
        return result;        
    }
    
    inline const vector<string> OVSQLiteKeyValueDataTable::keysForValue(const string& value)
    {
        vector<string> result;
        OVSQLiteStatement* statement = m_source->connection()->prepare("SELECT key FROM %Q WHERE value = %Q", m_tableName.c_str(), value.c_str());
        if (statement) {
            while (statement->step() == SQLITE_ROW) {
                string key = statement->textOfColumn(0);
                
                // we don't want property get into it
                if (!OVWildcard::Match(key, OVPropertyStringInternalPrefix "*")) {                
                    result.push_back(key);
                }
            }
            
            delete statement;
        }
        
        return result;        
    }
    
    inline const vector<pair<string, string> > OVSQLiteKeyValueDataTable::valuesForKey(const OVWildcard& expression)
    {
        pair<string, string> exp = OVSQLiteHelper::SQLiteStringFromWildcard(expression);
                    
        vector<pair<string, string> > result;
        OVSQLiteStatement* statement = m_source->connection()->prepare("SELECT key, value FROM %Q WHERE key like %Q escape %Q", m_tableName.c_str(), exp.first.c_str(), exp.second.c_str());
        if (statement) {
            while (statement->step() == SQLITE_ROW) {
                result.push_back(pair<string, string>(statement->textOfColumn(0), statement->textOfColumn(1)));
            }
            
            delete statement;
        }
        
        return result;        
    }
    
    inline const string OVSQLiteKeyValueDataTable::valueForProperty(const string& property)
    {
        return m_source->valueForPropertyInTable(property, m_tableName);
    }    
};

#endif