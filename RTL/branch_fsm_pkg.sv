package branch_fsm_pkg; // package that holds the decision states for branches
typedef enum logic [1:0] { // 2 bit dynamic branch predictor uses reinforcement to determine whether to branch
    STRONG_NOT_TAKEN, WEAK_NOT_TAKEN,
    WEAK_TAKEN, STRONG_TAKEN
} branch_state;
endpackage
