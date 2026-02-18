#pragma once
#include <array>
#include <cstdint>
#include <string>

namespace model_cfg {
constexpr std::size_t DATA_WIDTH = 64;
constexpr std::size_t WORD_WIDTH = 32;
constexpr std::size_t DEPTH = 256;
}

class pc {
private:
    int rst_n {};
    int pc_src {};
    uint64_t pc_branch {};
    uint64_t pc_current {};

public:
    uint64_t update_pc() {
        if (!rst_n) {
            pc_current = 0;
        } else {
            if (pc_src) {
                pc_current = pc_branch;
            } else {
                pc_current += 4;
            }
        }
        return pc_current;
    };
};

class instr_mem {
private:
    std::array<uint32_t, model_cfg::DEPTH> memory_{};
    uint32_t instruction_{};
    uint64_t pc_addr_{};

public:
    bool load_hex(const std::string& file_path);
    void tick(uint64_t addr);
    uint32_t instruction() const { return instruction_; }
    uint64_t pc_addr() const { return pc_addr_; }
    uint32_t read_instr(uint64_t addr) const;
};

class reg_file{

};

class main_ctrl {

};

class alu_ctrl {

};

class alu {

};

class imm_gen {

};

class branch_calc {

};

class branch_execute {

};

class data_mem {

};

class wb {

};