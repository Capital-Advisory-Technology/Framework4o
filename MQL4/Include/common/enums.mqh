#property copyright "Framework 4"
#property strict

enum OrderAction {
    OA_OPEN_LONG,
    OA_OPEN_SHORT,
    OA_CONFIRMED,
    OA_CLOSE,
    OA_IGNORE
};

enum AllowedOrder {
    OPEN_LONG = 0,
    OPEN_SHORT = 1,
    OPEN_BOTH = 2
};

enum PositionStatus {
    AVAILABLE_TO_OPEN,
    IS_OPENED
};
