#property copyright "Framework 4"
#property strict

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 clrChocolate
#property indicator_color2 clrRoyalBlue
#property indicator_color3 clrFireBrick

extern int period = 35;
extern int price = 0;
extern int Shift = 0;

double BufferGreen[];
double BufferYellow[];
double BufferRed[];

int init() {
   int i;
   for (i = 0; i < 3; i++) {
      SetIndexStyle(i,DRAW_LINE);
      SetIndexDrawBegin(i,period);
      SetIndexShift(i,Shift);
   }

   SetIndexBuffer(0,BufferYellow);
   SetIndexBuffer(1,BufferGreen);
   SetIndexBuffer(2,BufferRed);

   return(0); 
}

int start() {
   double tmp1, tmp2, tmp3;
   
   int counted_bars=IndicatorCounted();
   int i, limit;

   if(counted_bars < 0) return(-1);
   if(counted_bars > 0) counted_bars--;

   limit = Bars - counted_bars;

   for (i = limit; i >= 0; i--) {
      tmp1 = iMA(Symbol(),0,period,0,MODE_SMA,price,i);
      tmp2 = iMA(Symbol(),0,period,0,MODE_LWMA,price,i);
      tmp3 = 3.0*tmp2-2.0*tmp1;

      BufferGreen[i] =tmp3;
      BufferYellow[i]=tmp3;
      BufferRed[i]   =tmp3;

      if (BufferYellow[i] > BufferYellow[i+1]) {
         BufferRed[i] = EMPTY_VALUE;
      } else if (BufferYellow[i] < BufferYellow[i+1]) {
         BufferGreen[i] = EMPTY_VALUE;
      } else {
         BufferRed[i] = EMPTY_VALUE;         
         BufferGreen[i] = EMPTY_VALUE;
      }
   }
   return(0); 
}


