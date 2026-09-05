const VendorAgent = require("../../models/authModels/vendorAgent.model");

async function getAllVendors(req, res) {
    try {
        if (req.agentRole !== "buyer-agent") {
            return res.status(403).json({ message: "Forbidden", success: false });
        }

        // Fetch vendors, excluding sensitive data like passwords or full catalogs
        const vendors = await VendorAgent.find({}, "companyName reputationScore status _id")
            .sort({ reputationScore: -1 }); // Highest trust first

        return res.status(200).json({
            success: true,
            count: vendors.length,
            vendors: vendors
        });
    } catch (error) {
        console.error("Error fetching vendors:", error);
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { getAllVendors };