/* 
 * File: branch_pred_pkg.sv
 * Brought up by Md. Jannatul Nayem
 * Organization: Alpha Science Lab
 * April 2026
 */

package branch_pred_pkg;

    typedef struct packed {
        logic        valid;          // Is this a branch?
        logic [31:0] pc;             // Address of branch instruction
        logic        predicted_taken;
        logic [31:0] target;         // Predicted target address
    } pred_t;

    typedef struct packed {
        logic        valid;          // Is this a branch update?
        logic [31:0] pc;             // Branch PC
        logic        taken;          // Actual outcome
        logic [31:0] target;         // Actual target
    } update_t;
    
    // BTB Entry Definition
    typedef struct packed {
        logic        valid;
        logic [29:0] tag;           // PC[31:2]
        logic [1:0]  counter;       // 2-bit saturating counter
        logic [31:0] target;
    } btb_entry_t;

endpackage
