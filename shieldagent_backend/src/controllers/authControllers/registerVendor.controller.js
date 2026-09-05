const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { nanoid } = require("nanoid");
require("dotenv").config();

const vendorAgentModel = require("../../models/authModels/vendorAgent.model");

async function regsiterVendorAgent(req, res) {
    try {
        const { companyName, email, password } = req.body;

        if (!companyName || !email || !password) {
            return res.status(400).json({
                message: "Please fill all required fields",
                success: false
            });
        }

        const isExisting = await vendorAgentModel.findOne({ email });
        if (isExisting) {
            return res.status(400).json({
                message: "Email is already in use",
                success: false
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);
        const apiKey = `sa_live_${nanoid(15)}`;

        const newAgent = new vendorAgentModel({
            companyName: companyName,
            email: email,
            passwordHash: passwordHash,
            role: "vendor-agent",
            apiKey: apiKey
        });

        await newAgent.save();

        const token = jwt.sign(
            {
                userId: newAgent._id,
                email: email
            },
            process.env.JSON_SECRET,
            {
                expiresIn: '30d'
            }
        );

        return res.status(201).json({
            message: "Vendor agent registered successfully",
            success: true,
            token: token,
            agent: {
                companyName: newAgent.companyName,
                email: newAgent.email,
                role: newAgent.role,
                apiKey: newAgent.apiKey,
                reputationScore: newAgent.reputationScore,
                status: newAgent.status
            }
        });
    } catch (error) {
        console.error('Error in registering the vendor agent:', error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    regsiterVendorAgent
};