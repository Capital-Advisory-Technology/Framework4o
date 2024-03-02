#property copyright "Framework 4"
#property strict
/*
   Custom logger for enabling/disbaling log printing. 
   Example how to enable/disable printing is in EA_TEMPLATE.
   Currently does not support passing variables with comma.
   Example on how to add log: Logger::log("Hello " + "World");
*/
class Logger {
   public:
      static bool isDebug;
   
   static void log(string msg) {
      if (isDebug) Print(msg);
   }

};

bool Logger::isDebug = true;