#include <CAT/common/database/db.mqh>
#include <CAT/common/database/queries.mqh>
#include <CAT/common/session.mqh>
#include <CAT/common/logger.mqh>

class BacktestExporter {
    private:
        Database* db;
        
        string dateFrom;
        double accountStartBalance;


    public:
        BacktestExporter() {
            this.db = new Database();

            this.accountStartBalance = AccountBalance();
            this.dateFrom = getCurrentDateTime();
        }

        ~BacktestExporter() {
            delete db;
        }

        void exportBacktest(string strategyName, string inputJson, string sessionLimits) {
            string backtestQuery = insertBacktestQuery(strategyName, inputJson, sessionLimits, accountStartBalance, dateFrom);
            db.insertData(backtestQuery);

            int btId = (int)db.lastInsertId();
            string positionsQuery = insertPositionsQuery(btId);
            db.insertData(positionsQuery);
        }

};
