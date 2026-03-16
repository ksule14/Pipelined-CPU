package branch_fsm_pkg;
typedef enum logic [1:0] {
    STRONG_NOT_TAKEN, WEAK_NOT_TAKEN,
    WEAK_TAKEN, STRONG_TAKEN
} branch_state;
endpackage
