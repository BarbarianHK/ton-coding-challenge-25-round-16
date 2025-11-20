;; PaymentRetryAgent.tolk
;; Contract A: Sends payment with QueryID and tracks failures
;; 合约 A：发送带有 QueryID 的支付请求，并追踪失败的交易

#include "imports/stdlib.fc";

;; Storage: Last failed Query ID
;; 存储：上一次失败的 Query ID
(int) load_last_failed_id() inline {
    slice ds = get_data().begin_parse();
    if (ds.slice_bits() == 0) { return 0; }
    return ds~load_uint(64);
}

() save_last_failed_id(int query_id) impure inline {
    set_data(begin_cell().store_uint(query_id, 64).end_cell());
}

() recv_internal(int my_balance, int msg_value, cell in_msg_full, slice in_msg_body) impure {
    slice cs = in_msg_full.begin_parse();
    int flags = cs~load_uint(4);

    ;; --- HANDLE RICH BOUNCE (处理回弹) ---
    if (flags & 1) { 
        ;; When a message bounces, the body contains: [32 bit 0xFFFFFFFF] + [Original Message Body]
        ;; 当消息回弹时，body 包含：[32位 0xFFFFFFFF] + [原始消息体]
        
        ;; Skip the bounce header (0xFFFFFFFF)
        ;; 跳过回弹头
        in_msg_body~skip_bits(32); 
        
        ;; Now we are reading the ORIGINAL data we sent to Contract B
        ;; 现在我们正在读取发送给合约 B 的原始数据
        
        ;; We expect an OpCode(32) and a QueryID(64)
        ;; 我们预期有一个操作码(32位)和一个查询ID(64位)
        if (in_msg_body.slice_bits() >= 96) {
            int original_op = in_msg_body~load_uint(32);
            int original_query_id = in_msg_body~load_uint(64);
            
            ;; Logic: Save the ID of the failed transaction
            ;; 逻辑：保存失败交易的 ID
            save_last_failed_id(original_query_id);
        }
        return ();
    }

    ;; --- NORMAL EXECUTION (正常执行) ---
    
    ;; Assume target address is hardcoded for this demo or passed in body
    ;; 假设目标地址是硬编码的
    slice target_address = "EQD__________________________________________0"; ;; Placeholder
    
    ;; Generate a unique Query ID based on time (or passed from wallet)
    ;; 基于时间生成唯一的 Query ID
    int current_query_id = now(); 

    var msg_body = begin_cell()
        .store_uint(0x506179, 32)      ;; OpCode: "Pay"
        .store_uint(current_query_id, 64) ;; QueryID: Unique identifier / 唯一标识符
        .end_cell();

    var msg = begin_cell()
        .store_uint(0x18, 6)           ;; Bounceable = True / 可回弹
        .store_slice(target_address)
        .store_coins(0)
        .store_uint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .store_ref(msg_body)
        .end_cell();

    send_raw_message(msg, 64);
}

;; Getter to see what failed
get_method last_error_id() {
    return load_last_failed_id();
}
