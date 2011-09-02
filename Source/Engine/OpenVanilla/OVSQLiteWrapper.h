//
// OVSQLiteWrapper.h
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

#ifndef OVSQLite3Wrapper
#define OVSQLite3Wrapper

#include <sqlite3.h>

#if defined(__APPLE__)
    #include <OpenVanilla/OpenVanilla.h>
#else
    #include "OpenVanilla.h"
#endif

// For status codes (SQLITE_OK, SQLITE_ERROR, etc.), please refer to sqlite3.h

namespace OpenVanilla {
    using namespace std;

    class OVSQLiteStatement;

    class OVSQLiteConnection {
    public:
        // remember to manage the object returned by this class member function
        static OVSQLiteConnection* Open(const string& filename = ":memory:");
        ~OVSQLiteConnection();
    
        int lastError();
        const char* lastErrorMessage();
        
        int execute(const char* sqlcmd, ...);
        OVSQLiteStatement* prepare(const char* sqlcmd, ...);

        // helper for table creation and detection
        bool hasTable(const string& tableName);
        bool dropTable(const string& tableName);
        bool createTable(const string& tableName, const string& columnString = "key, value", bool dropIfExists = false);
        bool createIndexOnTable(const string& indexName, const string& tableName, const string& indexColumns = "key");
    
        sqlite3* connection();
		const string filename();
    
    protected:
        sqlite3* m_connection;
		string m_filename;
        OVSQLiteConnection(sqlite3* connection, const string& filename);
    };
    
    class OVSQLiteStatement {
    public:
        ~OVSQLiteStatement();
        
        int reset();
        
        // *nota bene* column starts from 1 !
        int bindTextToColumn(const char*str, int column);
        int bindTextToColumn(const string& str, int column);
        int bindIntToColumn(int value, int column);
        int bindDoubleToColumn(double value, int column);
        
        int step();
        int columnCount();
        const char* textOfColumn(int column);
        int intOfColumn(int column);
        double doubleOfColumn(int column);

    protected:
        sqlite3_stmt* m_statement;
        
        friend class OVSQLiteConnection;
        OVSQLiteStatement(sqlite3_stmt* statement);
    };
    
    inline sqlite3* OVSQLiteConnection::connection()
    {
        return m_connection;
    }
    
    inline OVSQLiteConnection* OVSQLiteConnection::Open(const string& filename)
    {
        sqlite3* connection;
        
        if (sqlite3_open(filename.c_str(), &connection) != SQLITE_OK)
            return 0;
            
        if (!connection)
            return 0;
            
        return new OVSQLiteConnection(connection, filename);
    }
    
    inline OVSQLiteConnection::OVSQLiteConnection(sqlite3* connection, const string& filename)
        : m_connection(connection)
		, m_filename(filename)
    {        
    }
    
    inline OVSQLiteConnection::~OVSQLiteConnection()
    {

		int result = sqlite3_close(m_connection);
        if (result) {
            ;
        }
    }
    
	inline const string OVSQLiteConnection::filename()
	{
		return m_filename;
	}
	
    inline int OVSQLiteConnection::lastError()
    {
        return sqlite3_errcode(m_connection);
    }
    
    inline const char* OVSQLiteConnection::lastErrorMessage()
    {
        return sqlite3_errmsg(m_connection);
    }
    
    inline int OVSQLiteConnection::execute(const char* sqlcmd, ...)
    {
        va_list l;
        va_start(l, sqlcmd);
        char* cmd = sqlite3_vmprintf(sqlcmd, l);
        va_end(l);
        int result = sqlite3_exec(m_connection, cmd, NULL, NULL, NULL);
        sqlite3_free(cmd);
        return result;        
    }
    
    inline OVSQLiteStatement* OVSQLiteConnection::prepare(const char* sqlcmd, ...)
    {
        va_list l;
        va_start(l, sqlcmd);
        char* cmd = sqlite3_vmprintf(sqlcmd, l);
        va_end(l);

        sqlite3_stmt* stmt;
        OVSQLiteStatement* result = 0;
        
        const char* remainingSt = 0;
        if (sqlite3_prepare_v2(m_connection, cmd, -1, &stmt, &remainingSt) == SQLITE_OK)
            result = new OVSQLiteStatement(stmt);
        sqlite3_free(cmd);
        
        return result;
    }
    
    inline bool OVSQLiteConnection::hasTable(const string& tableName)
    {
        bool result = false;
        OVSQLiteStatement* statement = prepare("SELECT name FROM sqlite_master WHERE name = %Q", tableName.c_str());        
        if (statement) {
            if (statement->step() == SQLITE_ROW) {
                result = true;
                while (statement->step() == SQLITE_ROW) ;
            }

            delete statement;
        }
        
        return result;
    }

    inline bool OVSQLiteConnection::dropTable(const string& tableName)
    {
        return SQLITE_OK == execute("DROP TABLE %Q", tableName.c_str());
    }
    
    inline bool OVSQLiteConnection::createTable(const string& tableName, const string& columnString, bool dropIfExists)
    {
        if (hasTable(tableName)) {
            if (dropIfExists) {
                if (!dropTable(tableName))
                    return false;
            }
            else {
                return false;
            }       
        }
        
            
        return SQLITE_OK == execute("CREATE TABLE %Q (%s)", tableName.c_str(), columnString.c_str());
    }
    
    inline bool OVSQLiteConnection::createIndexOnTable(const string& indexName, const string& tableName, const string& indexColumns)
    {
        return SQLITE_OK == execute("CREATE INDEX %Q on %Q (%s)", indexName.c_str(), tableName.c_str(), indexColumns.c_str());        
    }    

    inline OVSQLiteStatement::OVSQLiteStatement(sqlite3_stmt* statement)
        : m_statement(statement)
    {            
    }
    
    inline OVSQLiteStatement::~OVSQLiteStatement()
    {
        sqlite3_finalize(m_statement);
    }
    
    inline int OVSQLiteStatement::reset()
    {
        return sqlite3_reset(m_statement);
    }

    inline int OVSQLiteStatement::bindTextToColumn(const char* str, int column)
    {
        return sqlite3_bind_text(m_statement, column, str, -1, SQLITE_TRANSIENT);
    }

    inline int OVSQLiteStatement::bindTextToColumn(const string& str, int column)
    {
        return bindTextToColumn(str.c_str(), column);
    }

    inline int OVSQLiteStatement::bindIntToColumn(int value, int column)
    {
        return sqlite3_bind_int(m_statement, column, value);
    }

    inline int OVSQLiteStatement::bindDoubleToColumn(double value, int column)
    {
        return sqlite3_bind_double(m_statement, column, value);
    }

    inline int OVSQLiteStatement::step()
    {
        return sqlite3_step(m_statement);
    }

    inline int OVSQLiteStatement::columnCount()
    {
        return sqlite3_column_count(m_statement);
    }

    inline const char* OVSQLiteStatement::textOfColumn(int column)
    {
        return (const char*)sqlite3_column_text(m_statement, column);
    }

    inline int OVSQLiteStatement::intOfColumn(int column)
    {
        return sqlite3_column_int(m_statement, column);
    }

    inline double OVSQLiteStatement::doubleOfColumn(int column)
    {
        return sqlite3_column_double(m_statement, column);
    }
};

#endif