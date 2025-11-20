;; ServiceDeprecated.tolk
;; Contract B: Rejects payments because service is down
;; 合约 B：拒绝支付，因为服务已停止

#include "imports/stdlib.fc";

const op::pay = 0x506179; ;; "Pay"

() recv_internal(int my_balance, int msg_value, cell in_msg_full, slice in_msg_body) impure {
    
    slice cs = in_msg_full.begin_parse();
    int flags = cs~load_uint(4);

    ;; Ignore bounced messages
    if (flags & 1) { return (); }

    ;; Check if body is empty
    if (in_msg_body.slice_empty?()) { return (); }

    ;; Load OpCode
    int op = in_msg_body~load_uint(32);

    ;; Logic: If someone tries to Pay, we reject it.
    ;; 逻辑：如果有人尝试支付，我们拒绝。
    if (op == op::pay) {
        ;; Throw error 404 (Not Found / Service Down)
        ;; 抛出错误 404 (未找到/服务停止)
        ;; This triggers the bounce back to Contract A
        ;; 这将触发回弹给合约 A
        throw(404);
    }
    
    ;; Accept other ops or just end
}
