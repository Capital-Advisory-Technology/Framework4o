//+------------------------------------------------------------------+
//|                                                           DB.mqh |
//|                                                              CAT |
//|                                                                  |
//+------------------------------------------------------------------+


#include <SQLite3/Statement.mqh>
#include <CAT/common/logger.mqh>

/*
   Database class to establish connection with DB and execute queries.
*/
class Database
{

private:
    string dbName;
    string filesPath;
    string dbPath;
    SQLite3 *db;


public:
    Database::Database(void) {
        dbName = "mt4_backtests.db";
        filesPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files";
        dbPath = filesPath + "\\" + dbName;
        SQLite3::initialize();
        db = new SQLite3(dbPath, SQLITE_OPEN_READWRITE);
    };

    Database::Database(string name) {
        dbName = name;
        filesPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files";
        dbPath = filesPath + "\\" + dbName;
        SQLite3::initialize();
        db = new SQLite3(dbPath, SQLITE_OPEN_READWRITE);
    };

    ~Database() {
        SQLite3::shutdown();
        delete db;
    }

    long lastInsertId() {
        return db.getLastInsertRowId();
    }

    void insertData(string sql) {
        Statement s(db, sql);
        if (!s.isValid()) {
            Print(">> SQLite: Failed to execute", db.getErrorMsg());
            return;
        }

        int r = s.step();
        if (r == SQLITE_OK) Logger::log(">>> Step finished.");
        else if (r == SQLITE_DONE) {
            // Ignore
        }
        else Print(">> SQLite: Failed to execute", db.getErrorMsg());
    }
};
