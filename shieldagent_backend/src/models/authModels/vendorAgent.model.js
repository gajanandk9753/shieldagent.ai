const mongoose = require("mongoose");

const catalogItemSchema = new mongoose.Schema({
    itemId: {
        type: String, 
        required: true,
        trim: true
    },
    name: { 
        type: String, 
        required: true,
        trim: true
    },
    price: { 
        type: Number, 
        required: true 
    }
}, { _id: false });

const vendorAgentSchema = new mongoose.Schema({
    companyName: {
        type: String,
        required: true,
        trim: true
    },
    email: { 
        type: String, 
        required: true, 
        unique: true,
        trim: true
    },
    passwordHash: { 
        type: String, 
        required: true 
    },
    role: { 
        type: String, 
        default: "vendor-agent" 
    },
    apiKey: { 
        type: String, 
        required: true, 
        unique: true 
    },
    status: { 
        type: String, 
        enum: ['ACTIVE', 'SUSPENDED'], 
        default: 'ACTIVE' 
    },
    reputationScore: { 
        type: Number, 
        default: 100 
    },
    catalog: [catalogItemSchema]
}, { 
    timestamps: true 
});

module.exports = mongoose.model("VendorAgent", vendorAgentSchema);