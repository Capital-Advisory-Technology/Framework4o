#property copyright "Framework 4"
#property strict

class Logger {
   public:
      static bool isDebug;
   
   static void log(string msg) {
      if (isDebug) Print(msg);
   }

};

bool Logger::isDebug = true;