const mongoose = require("mongoose");

const evaluationSchema = new mongoose.Schema({
    buyerId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "BuyerAgent",
        reuqired : true
    },
    vendorId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "VendorAgent",
        required : true
    },
    decision : {
        type : String,
        enum : ["AUTO_APPROVE", "REQUIRES_PERMISSION", "BLOCKED"],
        required : true
    },
    riskScore : {
        type : Number,
        required : true
    },
    escrowPlan : {
        advancePct : { type : Number, required : true},
        tranches : { type : Number, require : true}
    },
    expiresAt : {
        type : Date,
        required : true
    },
    consumed : {
        type : Boolean,
        default : false
    }
}, {
    timestamps : true
});

module.exports = mongoose.model("Evaluation", evaluationSchema);