const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    transactionId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "Transaction",
        required: true
    },
    decision: {
        type: String,
        required: true
    },
    reason: {
        type: String,
        required: true
    },
    riskScore: {
        type: Number,
        required: true
    },
    actor: {
        type: String,
        default: "system"
    }
}, {
    timestamps : true
})

module.exports = mongoose.model("AuditLog", auditLogSchema);